//
//  ScheduleEventView.swift
//  ScheduleFeature
//

import SwiftUI
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
        .onAppear {
            interaction.lockedAxis = nil
        }
        .onDisappear {
            interaction.reset()
        }
    }

    private func openEventDetails() {
        guard interaction.offsetX == 0 else { return }
        onSelect(.navigation(.onEventDetails(viewModel)))
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

            content()
                .offset(x: interaction.offsetX)
                .modifier(HorizontalRowSwipeModifier(
                    interaction: interaction,
                    revealWidth: swipeThreshold
                ))
        }
        .overlay(alignment: .topTrailing) {
            if showsOptionsButton {
                EventOptionsButton(action: optionsAction)
                    .fixedSize()
                    .offset(x: interaction.offsetX)
            }
        }
    }
}

private struct HorizontalRowSwipeModifier: ViewModifier {
    @ObservedObject var interaction: ScheduleEventRowInteraction
    let revealWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height

                        if interaction.lockedAxis == nil {
                            guard abs(dx) > 10 || abs(dy) > 10 else { return }
                            interaction.lockedAxis = abs(dx) > abs(dy) ? .horizontal : .vertical
                            if interaction.lockedAxis == .horizontal {
                                interaction.startOffsetX = interaction.offsetX
                            }
                        }

                        guard interaction.lockedAxis == .horizontal else { return }

                        let newOffset = interaction.startOffsetX + dx
                        interaction.offsetX = min(max(newOffset, -revealWidth), 0)
                    }
                    .onEnded { value in
                        defer { interaction.lockedAxis = nil }

                        guard interaction.lockedAxis == .horizontal else { return }

                        let shouldOpen = -(interaction.startOffsetX + value.translation.width) > revealWidth / 2
                        withAnimation(.easeOut(duration: 0.2)) {
                            interaction.offsetX = shouldOpen ? -revealWidth : 0
                            interaction.startOffsetX = interaction.offsetX
                        }
                    }
            )
    }
}
