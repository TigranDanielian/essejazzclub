//
//  EventView.swift
//  Services
//
//  Created by Tigran Danielian on 09.06.2025.
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
        SwipableView(offsetX: $dragOffset, startOffsetX: $startDragOffset) {
            EventContextButtons(viewModel: viewModel) { onSelect(.contextAction($0)) }
        } content: {
            AnyView(uiFactory.produce(unit: .event(viewModel)))
        }
        .environment(\.eventSwipeToggle, toggleSwipeOffset)
        .onTapGesture {
            onSelect(.navigation(.onEventDetails(viewModel)))
        }
    }

    private func toggleSwipeOffset() {
        withAnimation {
            dragOffset = dragOffset == 0 ? -EventSwipeMetrics.revealWidth : 0
            startDragOffset = dragOffset
        }
    }
}

struct SwipableView<Content: View, SwipeContent: View>: View {
    @Binding var offsetX: CGFloat
    @Binding private var startOffsetX: CGFloat
    @GestureState private var isDragging = false

    private let swipeThreshold = EventSwipeMetrics.revealWidth

    let swipeContent: () -> SwipeContent
    let content: () -> Content

    init(offsetX: Binding<CGFloat>,
         startOffsetX: Binding<CGFloat>,
         @ViewBuilder swipeContent: @escaping () -> SwipeContent,
         @ViewBuilder content: @escaping () -> Content) {
        self._offsetX = offsetX
        self._startOffsetX = startOffsetX
        self.swipeContent = swipeContent
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                swipeContent()
                    .rotationEffect(.degrees(180))
                    .scaleEffect(offsetX / EventSwipeMetrics.revealWidth, anchor: .center)
            }

            content()
                .offset(x: offsetX)
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            let newOffset = startOffsetX + value.translation.width
                            offsetX = min(max(newOffset, -swipeThreshold), 0)
                        }
                        .onEnded { value in
                            withAnimation {
                                if -value.translation.width > swipeThreshold / 2 {
                                    offsetX = -swipeThreshold
                                } else {
                                    offsetX = 0
                                }
                                startOffsetX = offsetX
                            }
                        }
                )
        }
    }
}
