//
//  ScheduleEventView.swift
//  ScheduleFeature
//

import SwiftUI
import UIKit
import Core
import SharedInfrastructure

private enum EventSwipeMetrics {
    static let revealWidth: CGFloat = 80
}

struct ScheduleEventView: View {
    @ObservedObject var viewModel: EventViewModel
    @StateObject private var interaction: ScheduleEventRowInteraction
    var onSelect: EventActionHandler = { _ in }

    init(
        viewModel: EventViewModel,
        onSelect: @escaping EventActionHandler = { _ in }
    ) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        _interaction = StateObject(wrappedValue: ScheduleEventRowInteraction())
    }

    var body: some View {
        SwipableView(
            interaction: interaction,
            showsOptionsButton: viewModel.hasContextMenu,
            optionsAction: toggleSwipeOffset
        ) {
            EventContextButtons(viewModel: viewModel) { onSelect(.contextAction($0)) }
        } content: {
            EventView(viewModel: viewModel)
                .environment(\.eventShowsOptionsButton, false)
                .environment(\.eventCardTap, openEventDetails)
        }
        .id(viewModel.id)
        .onDisappear {
            interaction.reset()
        }
    }

    private func openEventDetails() {
        guard interaction.offsetX == 0 else { return }
        onSelect(.navigation(.onEventDetails(
            viewModel,
            heroTransitionSourceID: EventHeroTransitionSourceID.card(
                occurrenceIdentifier: viewModel.occurrenceIdentifier
            )
        )))
    }

    private func toggleSwipeOffset() {
        withAnimation(.easeOut(duration: 0.2)) {
            let target: CGFloat = interaction.offsetX == 0 ? -EventSwipeMetrics.revealWidth : 0
            interaction.offsetX = target
            interaction.startOffsetX = target
        }
    }
}

private struct SwipableView<Content: View, SwipeContent: View>: View {
    @ObservedObject var interaction: ScheduleEventRowInteraction

    private let showsOptionsButton: Bool
    private let optionsAction: () -> Void
    private let swipeThreshold = EventSwipeMetrics.revealWidth

    let swipeContent: () -> SwipeContent
    let content: () -> Content

    init(
        interaction: ScheduleEventRowInteraction,
        showsOptionsButton: Bool = false,
        optionsAction: @escaping () -> Void = {},
        @ViewBuilder swipeContent: @escaping () -> SwipeContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.interaction = interaction
        self.showsOptionsButton = showsOptionsButton
        self.optionsAction = optionsAction
        self.swipeContent = swipeContent
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                swipeContent()
                    .rotationEffect(.degrees(180))
                    .scaleEffect(interaction.offsetX / swipeThreshold, anchor: .center)
            }

            ZStack(alignment: .topTrailing) {
                ScheduleRowPanContainer(
                    interaction: interaction,
                    revealWidth: swipeThreshold,
                    content: content()
                )

                if showsOptionsButton {
                    EventOptionsButton(action: optionsAction)
                        .fixedSize()
                }
            }
            .offset(x: interaction.offsetX)
        }
    }
}

/// UIKit horizontal pan: не начинается при вертикальном движении — скролл списка не блокируется.
private struct ScheduleRowPanContainer<Content: View>: UIViewRepresentable {
    @ObservedObject var interaction: ScheduleEventRowInteraction
    let revealWidth: CGFloat
    let content: Content

    func makeCoordinator() -> Coordinator {
        Coordinator(interaction: interaction, revealWidth: revealWidth)
    }

    func makeUIView(context: Context) -> RowContainerView {
        let container = RowContainerView()
        container.coordinator = context.coordinator
        context.coordinator.container = container

        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        context.coordinator.hostingController = hosting
        container.setHostedView(hosting.view)
        container.installPanRecognizer()
        return container
    }

    func updateUIView(_ uiView: RowContainerView, context: Context) {
        context.coordinator.interaction = interaction
        context.coordinator.revealWidth = revealWidth
        context.coordinator.hostingController?.rootView = content
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var interaction: ScheduleEventRowInteraction
        var revealWidth: CGFloat
        weak var container: RowContainerView?
        weak var hostingController: UIHostingController<Content>?

        init(interaction: ScheduleEventRowInteraction, revealWidth: CGFloat) {
            self.interaction = interaction
            self.revealWidth = revealWidth
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            let translationX = pan.translation(in: pan.view).x

            switch pan.state {
            case .began:
                interaction.startOffsetX = interaction.offsetX
            case .changed:
                let newOffset = interaction.startOffsetX + translationX
                interaction.offsetX = min(max(newOffset, -revealWidth), 0)
            case .ended, .cancelled, .failed:
                let finalOffset = interaction.startOffsetX + translationX
                let shouldOpen = -finalOffset > revealWidth / 2
                withAnimation(.easeOut(duration: 0.2)) {
                    interaction.offsetX = shouldOpen ? -revealWidth : 0
                    interaction.startOffsetX = interaction.offsetX
                }
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view else { return false }

            if interaction.offsetX != 0 {
                return true
            }

            let velocity = pan.velocity(in: view)
            let translation = pan.translation(in: view)
            let absVX = abs(velocity.x)
            let absVY = abs(velocity.y)

            if absVX + absVY > 40 {
                return absVX > absVY
            }
            return abs(translation.x) > abs(translation.y)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }
    }

    final class RowContainerView: UIView {
        weak var coordinator: Coordinator?
        private let hostedContentView = UIView()
        private var panRecognizer: UIPanGestureRecognizer?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            addSubview(hostedContentView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: 100)
        }

        func setHostedView(_ view: UIView) {
            view.translatesAutoresizingMaskIntoConstraints = false
            hostedContentView.subviews.forEach { $0.removeFromSuperview() }
            hostedContentView.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: hostedContentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: hostedContentView.trailingAnchor),
                view.topAnchor.constraint(equalTo: hostedContentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: hostedContentView.bottomAnchor),
            ])
        }

        func installPanRecognizer() {
            guard panRecognizer == nil, let coordinator else { return }

            let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan))
            pan.delegate = coordinator
            pan.cancelsTouchesInView = false
            pan.delaysTouchesBegan = false
            pan.delaysTouchesEnded = false
            addGestureRecognizer(pan)
            panRecognizer = pan
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            hostedContentView.frame = bounds
        }
    }
}
