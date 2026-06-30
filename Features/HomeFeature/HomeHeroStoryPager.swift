//
//  HomeHeroStoryPager.swift
//  HomeFeature
//

import SwiftUI
import UIKit
import Services
import SharedInfrastructure

struct HomeHeroStoryScrollRequest: Equatable {
    let targetLoopIndex: Int
    let animated: Bool
    let id: UUID
}

struct HomeHeroStoryPager: UIViewControllerRepresentable {
    let events: [EventViewModel]
    let imageLoader: ImageLoader
    let onDetails: (EventViewModel) -> Void
    @Binding var loopIndex: Int
    @Binding var logicalIndex: Int
    @Binding var scrollRequest: HomeHeroStoryScrollRequest?
    let onLogicalIndexChange: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLogicalIndexChange: onLogicalIndexChange)
    }

    func makeUIViewController(context: Context) -> HomeHeroStoryPagerViewController {
        let controller = HomeHeroStoryPagerViewController()
        controller.coordinator = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: HomeHeroStoryPagerViewController, context: Context) {
        context.coordinator.onLogicalIndexChange = onLogicalIndexChange
        context.coordinator.updateBindings(loopIndex: $loopIndex, logicalIndex: $logicalIndex)

        controller.update(
            events: events,
            imageLoader: imageLoader,
            onDetails: onDetails,
            activeLoopIndex: loopIndex
        )

        if let request = scrollRequest, request.id != context.coordinator.lastHandledScrollRequestID {
            context.coordinator.lastHandledScrollRequestID = request.id
            controller.scrollToLoopIndex(request.targetLoopIndex, animated: request.animated)
            DispatchQueue.main.async {
                scrollRequest = nil
            }
        }
    }

    final class Coordinator {
        var onLogicalIndexChange: (Int) -> Void
        var lastHandledScrollRequestID: UUID?
        private var loopIndexBinding: Binding<Int>?
        private var logicalIndexBinding: Binding<Int>?

        init(onLogicalIndexChange: @escaping (Int) -> Void) {
            self.onLogicalIndexChange = onLogicalIndexChange
        }

        func updateBindings(loopIndex: Binding<Int>, logicalIndex: Binding<Int>) {
            loopIndexBinding = loopIndex
            logicalIndexBinding = logicalIndex
        }

        func reportPageChange(loopIndex: Int, logicalIndex: Int) {
            if loopIndexBinding?.wrappedValue != loopIndex {
                loopIndexBinding?.wrappedValue = loopIndex
            }
            if logicalIndexBinding?.wrappedValue != logicalIndex {
                logicalIndexBinding?.wrappedValue = logicalIndex
                onLogicalIndexChange(logicalIndex)
            }
        }
    }
}

final class HomeHeroStoryPagerViewController: UIViewController, UIScrollViewDelegate {
    weak var coordinator: HomeHeroStoryPager.Coordinator?

    private let scrollView = UIScrollView()
    private var hostingController: UIHostingController<AnyView>?

    private var events: [EventViewModel] = []
    private var imageLoader: ImageLoader?
    private var onDetails: ((EventViewModel) -> Void)?
    private var pageWidth: CGFloat = 0
    private var pageHeight: CGFloat = 0
    private var activeLoopIndex: Int = 1
    private var pendingInitialLoopIndex = 1
    private var lastBuiltEventIDs: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        scrollView.isPagingEnabled = true
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.bounces = true
        scrollView.clipsToBounds = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = view.bounds.width
        let height = view.bounds.height
        guard width > 0, height > 0 else { return }

        let sizeChanged = abs(width - pageWidth) > 0.5 || abs(height - pageHeight) > 0.5
        pageWidth = width
        pageHeight = height

        if sizeChanged || hostingController == nil || eventsChangedSinceLastBuild {
            rebuildContent()
            scrollToLoopIndex(pendingInitialLoopIndex, animated: false)
        }
    }

    func update(
        events: [EventViewModel],
        imageLoader: ImageLoader,
        onDetails: @escaping (EventViewModel) -> Void,
        activeLoopIndex: Int
    ) {
        let ids = events.map(\.occurrenceIdentifier)
        let contentChanged = ids != lastBuiltEventIDs
        let activePageChanged = self.activeLoopIndex != activeLoopIndex

        self.events = events
        self.imageLoader = imageLoader
        self.onDetails = onDetails
        self.activeLoopIndex = activeLoopIndex

        if contentChanged {
            pendingInitialLoopIndex = activeLoopIndex
            if pageWidth > 0 {
                rebuildContent()
                scrollToLoopIndex(activeLoopIndex, animated: false)
            }
        } else if activePageChanged, pageWidth > 0 {
            rebuildContent()
        }
    }

    private var eventsChangedSinceLastBuild: Bool {
        events.map(\.occurrenceIdentifier) != lastBuiltEventIDs
    }

    private var loopPageCount: Int {
        events.count + 2
    }

    private func event(atLoopIndex index: Int) -> EventViewModel {
        switch index {
        case 0:
            return events[events.count - 1]
        case events.count + 1:
            return events[0]
        default:
            return events[index - 1]
        }
    }

    private func rebuildContent() {
        guard events.count > 1, let imageLoader, let onDetails else { return }

        let width = pageWidth
        let height = pageHeight
        lastBuiltEventIDs = events.map(\.occurrenceIdentifier)

        let pages = HStack(spacing: 0) {
            ForEach(0 ..< loopPageCount, id: \.self) { index in
                let event = self.event(atLoopIndex: index)
                HomeHeroOverlaySlide(
                    event: event,
                    imageLoader: imageLoader,
                    onDetails: { onDetails(event) },
                    registersHeroTransitionSource: index == self.activeLoopIndex
                )
                .frame(width: width, height: height)
            }
        }

        let contentSize = CGSize(width: width * CGFloat(loopPageCount), height: height)

        if let hostingController {
            hostingController.rootView = AnyView(pages)
            hostingController.view.clipsToBounds = true
            hostingController.view.frame = CGRect(origin: .zero, size: contentSize)
        } else {
            let hosting = UIHostingController(rootView: AnyView(pages))
            hosting.view.backgroundColor = .clear
            hosting.view.clipsToBounds = true
            hosting.safeAreaRegions = []
            hostingController = hosting

            addChild(hosting)
            scrollView.addSubview(hosting.view)
            hosting.didMove(toParent: self)
            hosting.view.frame = CGRect(origin: .zero, size: contentSize)
        }

        scrollView.contentSize = contentSize
    }

    func scrollToLoopIndex(_ index: Int, animated: Bool) {
        let clamped = max(0, min(index, loopPageCount - 1))
        pendingInitialLoopIndex = clamped

        guard pageWidth > 0 else { return }

        scrollView.setContentOffset(
            CGPoint(x: CGFloat(clamped) * pageWidth, y: 0),
            animated: animated
        )

        if !animated {
            finalizePageChange()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finalizePageChange()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        finalizePageChange()
    }

    private func currentLoopIndex() -> Int {
        guard pageWidth > 0 else { return 1 }
        return Int(round(scrollView.contentOffset.x / pageWidth))
    }

    private func finalizePageChange() {
        guard events.count > 1, pageWidth > 0 else { return }

        var page = currentLoopIndex()
        let logical: Int

        if page == 0 {
            page = events.count
            scrollView.setContentOffset(CGPoint(x: pageWidth * CGFloat(page), y: 0), animated: false)
            logical = events.count - 1
        } else if page == events.count + 1 {
            page = 1
            scrollView.setContentOffset(CGPoint(x: pageWidth, y: 0), animated: false)
            logical = 0
        } else {
            logical = page - 1
        }

        coordinator?.reportPageChange(loopIndex: page, logicalIndex: logical)
    }
}
