//
//  HomeTopClampedScrollView.swift
//  HomeFeature
//

import SwiftUI
import UIKit
import Core

/// Пропускает тапы в зону баннера, когда шит ещё не поднят; иначе отдаёт их контенту скролла.
private final class HomeHeroPassthroughScrollView: UIScrollView {
    var bannerPassthroughHeight: CGFloat = 0

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else { return nil }
        guard bounds.contains(point) else { return nil }

        let contentY = point.y + contentOffset.y
        if contentY < bannerPassthroughHeight {
            return nil
        }

        return super.hitTest(point, with: event)
    }
}

/// Контейнер: скролл + `UIRefreshControl` у верхнего края шторки.
private final class HomeTopClampedScrollContainerView: UIView {
    weak var sheetRefreshControl: UIActivityIndicatorView?
    var sheetTopOffset: CGFloat = 0 {
        didSet {
            guard oldValue != sheetTopOffset else { return }
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let refreshControl = sheetRefreshControl else { return }
        let height = max(refreshControl.sizeThatFits(bounds.size).height, 44)
        refreshControl.frame = CGRect(
            x: 0,
            y: sheetTopOffset,
            width: bounds.width,
            height: height
        )
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else { return nil }

        for subview in subviews.reversed() {
            let converted = convert(point, to: subview)
            if let hit = subview.hitTest(converted, with: event) {
                return hit
            }
        }

        return nil
    }
}

/// Вертикальный скролл с `UIRefreshControl` у верхнего края шторки.
struct HomeTopClampedScrollView<Content: View>: UIViewControllerRepresentable {
    let showsIndicators: Bool
    let scrollClipDisabled: Bool
    let bounces: Bool
    let onRefresh: (() async -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        showsIndicators: Bool = true,
        scrollClipDisabled: Bool = false,
        bounces: Bool = true,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.scrollClipDisabled = scrollClipDisabled
        self.bounces = bounces
        self.onRefresh = onRefresh
        self.content = content
    }

    func makeUIViewController(context: Context) -> HomeTopClampedScrollViewController<Content> {
        let controller = HomeTopClampedScrollViewController(rootView: content())
        controller.showsIndicators = showsIndicators
        controller.scrollClipDisabled = scrollClipDisabled
        controller.bounces = bounces
        controller.onRefresh = onRefresh
        return controller
    }

    func updateUIViewController(_ controller: HomeTopClampedScrollViewController<Content>, context: Context) {
        controller.showsIndicators = showsIndicators
        controller.scrollClipDisabled = scrollClipDisabled
        controller.bounces = bounces
        controller.onRefresh = onRefresh
        controller.updateRootView(content())
    }
}

final class HomeTopClampedScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    private let scrollView = HomeHeroPassthroughScrollView()
    private let hostingController: UIHostingController<Content>
    private var isRefreshInFlight = false
    private var refreshControl: UIActivityIndicatorView?

    private var containerView: HomeTopClampedScrollContainerView {
        view as! HomeTopClampedScrollContainerView
    }

    var showsIndicators = true {
        didSet { scrollView.showsVerticalScrollIndicator = showsIndicators }
    }

    var scrollClipDisabled = false {
        didSet { scrollView.clipsToBounds = !scrollClipDisabled }
    }

    var bounces = true {
        didSet {
            scrollView.bounces = bounces
            scrollView.alwaysBounceVertical = bounces
        }
    }

    var onRefresh: (() async -> Void)? {
        didSet { updateRefreshControl() }
    }

    init(rootView: Content) {
        hostingController = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = HomeTopClampedScrollContainerView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        hostingController.view.backgroundColor = .clear
        hostingController.view.isUserInteractionEnabled = true
        hostingController.sizingOptions = .intrinsicContentSize
        hostingController.safeAreaRegions = []

        scrollView.bannerPassthroughHeight = HomeHeroSheetLayout.scrollHitExtensionHeight
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bounces = bounces
        scrollView.alwaysBounceVertical = bounces
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.showsVerticalScrollIndicator = showsIndicators
        scrollView.clipsToBounds = !scrollClipDisabled
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        hostingController.didMove(toParent: self)
        updateRefreshControl()
        applyFixedSheetRefreshPosition()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyFixedSheetRefreshPosition()
    }

    func updateRootView(_ rootView: Content) {
        hostingController.rootView = rootView
    }

    private func updateRefreshControl() {
        if onRefresh != nil {
            guard refreshControl == nil else { return }

            let control = UIActivityIndicatorView()
            control.tintColor = Colors.accentSheet
            control.isUserInteractionEnabled = false
            control.isHidden = true
            view.addSubview(control)
            containerView.sheetRefreshControl = control
            refreshControl = control
            applyFixedSheetRefreshPosition()
        } else if let refreshControl {
            refreshControl.removeFromSuperview()
            containerView.sheetRefreshControl = nil
            self.refreshControl = nil
        }
    }

    private func applyFixedSheetRefreshPosition() {
        containerView.sheetTopOffset = HomeHeroSheetLayout.scrollHitExtensionHeight
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let refreshControl else { return }
        let pullDistance = max(0, -scrollView.contentOffset.y)

        if pullDistance > HomeHeroSheetLayout.pullRefreshTriggerOffset {
            refreshControl.isHidden = false
            view.bringSubviewToFront(refreshControl)
            if !refreshControl.isAnimating, !isRefreshInFlight {
                refreshControl.startAnimating()
            }
        } else {
            refreshControl.stopAnimating()
            refreshControl.isHidden = true
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let pullDistance = max(0, -scrollView.contentOffset.y)
        if pullDistance > HomeHeroSheetLayout.pullRefreshTriggerOffset {
            triggerRefreshIfNeeded()
        } else if !isRefreshInFlight {
            refreshControl?.stopAnimating()
            refreshControl?.isHidden = true
        }
    }

    private func triggerRefreshIfNeeded() {
        guard let refreshControl, let onRefresh, !isRefreshInFlight else { return }

        isRefreshInFlight = true
        refreshControl.isHidden = false
        view.bringSubviewToFront(refreshControl)
        refreshControl.startAnimating()

        Task { @MainActor in
            await onRefresh()
            refreshControl.stopAnimating()
            isRefreshInFlight = false
            let pullDistance = max(0, -scrollView.contentOffset.y)
            refreshControl.isHidden = pullDistance == 0
        }
    }
}
