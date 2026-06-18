//
//  HomeTopClampedScrollView.swift
//  HomeFeature
//

import SwiftUI

/// Вертикальный скролл без «резинки» вниз от начальной позиции — шит не уезжает ниже слайдера.
struct HomeTopClampedScrollView<Content: View>: UIViewControllerRepresentable {
    let showsIndicators: Bool
    let scrollClipDisabled: Bool
    let bounces: Bool
    @ViewBuilder let content: () -> Content

    init(
        showsIndicators: Bool = true,
        scrollClipDisabled: Bool = false,
        bounces: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.scrollClipDisabled = scrollClipDisabled
        self.bounces = bounces
        self.content = content
    }

    func makeUIViewController(context: Context) -> HomeTopClampedScrollViewController<Content> {
        let controller = HomeTopClampedScrollViewController(rootView: content())
        controller.showsIndicators = showsIndicators
        controller.scrollClipDisabled = scrollClipDisabled
        controller.bounces = bounces
        return controller
    }

    func updateUIViewController(_ controller: HomeTopClampedScrollViewController<Content>, context: Context) {
        controller.showsIndicators = showsIndicators
        controller.scrollClipDisabled = scrollClipDisabled
        controller.bounces = bounces
        controller.updateRootView(content())
    }
}

final class HomeTopClampedScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let hostingController: UIHostingController<Content>

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

    init(rootView: Content) {
        hostingController = UIHostingController(rootView: rootView)
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
        hostingController.view.isUserInteractionEnabled = true
        hostingController.sizingOptions = .intrinsicContentSize
        hostingController.safeAreaRegions = []

        scrollView.delegate = self
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
    }

    func updateRootView(_ rootView: Content) {
        hostingController.rootView = rootView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        }
    }
}
