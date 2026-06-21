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
    var onSelect: EventActionHandler = { _ in }
    var uiFactory: any UIFactory
    @State private var dragOffset: CGFloat = 0
    @State private var startDragOffset: CGFloat = 0

    var body: some View {
        SwipableView(
            offsetX: $dragOffset,
            startOffsetX: $startDragOffset,
            showsOptionsButton: viewModel.hasContextMenu,
            optionsAction: toggleSwipeOffset
        ) {
            EventContextButtons(viewModel: viewModel) { onSelect(.contextAction($0)) }
        } content: {
            AnyView(
                uiFactory.produce(unit: .event(viewModel))
                    .environment(\.eventShowsOptionsButton, false)
                    .environment(\.eventCardTap, openEventDetails)
            )
        }
        .id(viewModel.id)
        .onDisappear {
            dragOffset = 0
            startDragOffset = 0
        }
    }

    private func openEventDetails() {
        guard dragOffset == 0 else { return }
        onSelect(.navigation(.onEventDetails(viewModel)))
    }

    private func toggleSwipeOffset() {
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = dragOffset == 0 ? -EventSwipeMetrics.revealWidth : 0
            startDragOffset = dragOffset
        }
    }
}

struct SwipableView<Content: View, SwipeContent: View>: View {
    @Binding var offsetX: CGFloat
    @Binding private var startOffsetX: CGFloat

    private let showsOptionsButton: Bool
    private let optionsAction: () -> Void
    private let swipeThreshold = EventSwipeMetrics.revealWidth

    let swipeContent: () -> SwipeContent
    let content: () -> Content

    init(
        offsetX: Binding<CGFloat>,
        startOffsetX: Binding<CGFloat>,
        showsOptionsButton: Bool = false,
        optionsAction: @escaping () -> Void = {},
        @ViewBuilder swipeContent: @escaping () -> SwipeContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._offsetX = offsetX
        self._startOffsetX = startOffsetX
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
                    .scaleEffect(offsetX / swipeThreshold, anchor: .center)
            }

            content()
                .offset(x: offsetX)
                .modifier(HorizontalRowSwipeModifier(
                    offsetX: $offsetX,
                    startOffsetX: $startOffsetX,
                    revealWidth: swipeThreshold
                ))
        }
        .overlay(alignment: .topTrailing) {
            if showsOptionsButton {
                Button(action: optionsAction) {
                    Image(uiImage: UIImage(resource: .options).withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding(2)
                        .foregroundStyle(Color(uiColor: Colors.accentSheet))
                }
                .buttonStyle(.plain)
                .padding(8)
                .offset(x: offsetX)
            }
        }
    }
}

private struct HorizontalRowSwipeModifier: ViewModifier {
    @Binding var offsetX: CGFloat
    @Binding var startOffsetX: CGFloat
    let revealWidth: CGFloat

    @State private var lockedAxis: Axis?

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height

                        if lockedAxis == nil {
                            guard abs(dx) > 10 || abs(dy) > 10 else { return }
                            lockedAxis = abs(dx) > abs(dy) ? .horizontal : .vertical
                            if lockedAxis == .horizontal {
                                startOffsetX = offsetX
                            }
                        }

                        guard lockedAxis == .horizontal else { return }

                        let newOffset = startOffsetX + dx
                        offsetX = min(max(newOffset, -revealWidth), 0)
                    }
                    .onEnded { value in
                        defer { lockedAxis = nil }

                        guard lockedAxis == .horizontal else { return }

                        let shouldOpen = -(startOffsetX + value.translation.width) > revealWidth / 2
                        withAnimation(.easeOut(duration: 0.2)) {
                            offsetX = shouldOpen ? -revealWidth : 0
                            startOffsetX = offsetX
                        }
                    }
            )
    }
}
