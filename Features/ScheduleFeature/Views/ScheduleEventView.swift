//
//  EventView.swift
//  Services
//
//  Created by Tigran Danielian on 09.06.2025.
//

import SwiftUI
import Core
import SharedInfrastructure

struct ScheduleEventView: View {
    @ObservedObject var viewModel: EventViewModel
    var onSelect: EventActionHandler = { _ in }
    var uiFactory: any UIFactory
    
    var body: some View {
        SwipableView(offsetX: $viewModel.dragOffset, startOffsetX: $viewModel.startDragOffset) {
            EventContextButtons(viewModel: viewModel) { onSelect(.contextAction($0)) }
        } content: {
            AnyView(uiFactory.produce(unit: .event(viewModel)))
        }
        .onTapGesture {
            onSelect(.navigation(.onEventDetails(viewModel)))
        }
    }
}

struct SwipableView<Content: View, SwipeContent: View>: View {
    @Binding var offsetX: CGFloat
    @Binding private var startOffsetX: CGFloat
    @GestureState private var isDragging = false

    private let swipeThreshold: CGFloat = 80

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
                    .scaleEffect(offsetX / 80, anchor: .center)
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
