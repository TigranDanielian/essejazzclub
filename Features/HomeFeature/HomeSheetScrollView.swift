//
//  HomeSheetScrollView.swift
//  HomeFeature
//

import SwiftUI
import UIKit
import Core

//TODO: Кривое решение, найти способ сделать по SwiftUI

/// Scroll поверх баннера: тапы по контенту — scroll, иначе — вью под ним в иерархии.
private final class HomeBannerPassthroughScrollView: UIScrollView {
    weak var passthroughContentView: UIView?

    private static var isForwardingPassthroughHit = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01, bounds.contains(point) else {
            return nil
        }

        if let passthroughContentView {
            let pointInContent = convert(point, to: passthroughContentView)
            if pointInContent.y < 0 {
                return forwardHitToViewsBelowScroll(at: point, with: event)
            }
        }

        guard let hit = super.hitTest(point, with: event) else {
            return nil
        }

        if hit === self {
            return nil
        }

        if let refreshControl, hit === refreshControl || hit.isDescendant(of: refreshControl) {
            return hit
        }

        if let passthroughContentView,
           hit === passthroughContentView || hit.isDescendant(of: passthroughContentView) {
            return hit
        }

        return nil
    }

    /// Пробрасывает тап sibling-вью, лежащим под scroll в ZStack. Ничего не кэширует.
    private func forwardHitToViewsBelowScroll(at point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !Self.isForwardingPassthroughHit else { return nil }
        guard let context = findPassthroughContext() else { return nil }

        let container = context.container
        let scrollBranchRoot = context.scrollBranchRoot

        guard let scrollIndex = container.subviews.firstIndex(of: scrollBranchRoot), scrollIndex > 0 else {
            return nil
        }

        Self.isForwardingPassthroughHit = true
        defer { Self.isForwardingPassthroughHit = false }

        let pointInContainer = convert(point, to: container)

        for index in stride(from: scrollIndex - 1, through: 0, by: -1) {
            let subview = container.subviews[index]
            let localPoint = subview.convert(pointInContainer, from: container)
            if let hit = deepestHitView(
                in: subview,
                at: localPoint,
                with: event,
                excludingScrollBranchRoot: scrollBranchRoot
            ) {
                return hit
            }
        }

        return nil
    }

    /// Прямой потомок ZStack-контейнера, внутри которого лежит scroll.
    private func findPassthroughContext() -> (container: UIView, scrollBranchRoot: UIView)? {
        var branchRoot: UIView = self
        while let parent = branchRoot.superview {
            if parent.subviews.count >= 2 {
                return (parent, branchRoot)
            }
            branchRoot = parent
        }
        return nil
    }

    /// Ручной hit-test без вызова `UIView.hitTest`, чтобы не уйти обратно в scroll.
    private func deepestHitView(
        in view: UIView,
        at point: CGPoint,
        with event: UIEvent?,
        excludingScrollBranchRoot excludedRoot: UIView
    ) -> UIView? {
        if view === excludedRoot || view.isDescendant(of: excludedRoot) {
            return nil
        }
        guard view.isUserInteractionEnabled, !view.isHidden, view.alpha >= 0.01 else {
            return nil
        }
        guard view.point(inside: point, with: event) else {
            return nil
        }

        for subview in view.subviews.reversed() {
            let localPoint = subview.convert(point, from: view)
            if let hit = deepestHitView(
                in: subview,
                at: localPoint,
                with: event,
                excludingScrollBranchRoot: excludedRoot
            ) {
                return hit
            }
        }

        return view
    }
}

struct HomeSheetScrollView<Content: View>: UIViewControllerRepresentable {
    let onRefresh: (() async -> Void)?
    @ViewBuilder let content: () -> Content

    func makeUIViewController(context: Context) -> Controller<Content> {
        Controller(rootView: content(), onRefresh: onRefresh)
    }

    func updateUIViewController(_ controller: Controller<Content>, context: Context) {
        controller.onRefresh = onRefresh
        controller.updateRootView(content())
    }

    final class Controller<Content: View>: UIViewController {
        private let scrollView = HomeBannerPassthroughScrollView()
        private let hostingController: UIHostingController<Content>
        private var refreshControl: UIRefreshControl?

        var onRefresh: (() async -> Void)? {
            didSet { updateRefreshControl() }
        }

        init(rootView: Content, onRefresh: (() async -> Void)?) {
            hostingController = UIHostingController(rootView: rootView)
            self.onRefresh = onRefresh
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .clear

            hostingController.view.backgroundColor = .clear
            hostingController.sizingOptions = .intrinsicContentSize
            hostingController.safeAreaRegions = []

            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.alwaysBounceVertical = true
            scrollView.bounces = true
            scrollView.clipsToBounds = false
            scrollView.showsVerticalScrollIndicator = false
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
            scrollView.passthroughContentView = hostingController.view
            updateRefreshControl()
        }

        func updateRootView(_ rootView: Content) {
            hostingController.rootView = rootView
        }

        private func updateRefreshControl() {
            if onRefresh != nil {
                guard refreshControl == nil else { return }

                let control = UIRefreshControl()
                control.tintColor = Colors.accentSheet
                control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
                scrollView.refreshControl = control
                refreshControl = control
                applySheetTopInset()
            } else if refreshControl != nil {
                scrollView.refreshControl = nil
                refreshControl = nil
                applySheetTopInset()
            }
        }

        private func applySheetTopInset() {
            let inset = refreshControl == nil ? 0 : HomeHeroSheetLayout.scrollPassthroughHeight
            scrollView.contentInset.top = inset
            scrollView.verticalScrollIndicatorInsets.top = inset

            guard inset > 0, !scrollView.isDragging, !scrollView.isDecelerating else { return }
            scrollView.contentOffset.y = -inset
        }

        @objc
        private func handleRefresh() {
            guard let onRefresh else {
                refreshControl?.endRefreshing()
                return
            }

            Task { @MainActor in
                await onRefresh()
                refreshControl?.endRefreshing()
                let inset = scrollView.contentInset.top
                if inset > 0 {
                    scrollView.contentOffset.y = -inset
                }
            }
        }
    }
}
