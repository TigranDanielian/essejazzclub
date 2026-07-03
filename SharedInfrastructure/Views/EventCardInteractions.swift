//
//  EventCardInteractions.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

public enum DayViewEventsLayout: Sendable {
    case stack
    case nativeSwipeActions(rowHeight: CGFloat = 112)
}

// MARK: - Context menu

public struct EventContextMenuItems: View {
    @ObservedObject private var viewModel: EventViewModel
    @ObservedObject private var favoriteState: FavoriteHeartButtonViewModel
    @ObservedObject private var calendarState: EventCalendarToggleViewModel
    private let showsDetailsAction: Bool
    private let onSelect: (EventContextButtonType) -> Void

    public init(
        viewModel: EventViewModel,
        showsDetailsAction: Bool = true,
        onSelect: @escaping (EventContextButtonType) -> Void
    ) {
        self.viewModel = viewModel
        self.showsDetailsAction = showsDetailsAction
        self.onSelect = onSelect
        _favoriteState = ObservedObject(wrappedValue: viewModel.favoriteHeartButtonViewModel)
        _calendarState = ObservedObject(wrappedValue: viewModel.calendarToggleViewModel)
    }

    public var body: some View {
        Group {
            Button {
                onSelect(.favorite(viewModel.eventId))
            } label: {
                Label(
                    favoriteState.isFavorite ? "Убрать из избранного" : "Добавить в избранное",
                    systemImage: favoriteState.isFavorite ? "heart.slash" : "heart"
                )
            }

            Button {
                onSelect(.calendar(viewModel))
            } label: {
                Label(
                    calendarState.isInCalendar ? "Удалить из календаря" : "Добавить в календарь",
                    systemImage: calendarState.isInCalendar ? "calendar.badge.minus" : "calendar.badge.plus"
                )
            }

            Button {
                onSelect(.share(viewModel))
            } label: {
                Label("Поделиться", systemImage: "square.and.arrow.up")
            }

            if showsDetailsAction {
                Button {
                    onSelect(.details(viewModel))
                } label: {
                    Label("Подробнее", systemImage: "info.circle")
                }
            }
        }
    }
}

private struct EventCardContextMenuModifier: ViewModifier {
    @ObservedObject var viewModel: EventViewModel
    var showsDetailsAction: Bool
    var onSelect: EventActionHandler?

    @Environment(\.eventActionHandler) private var environmentHandler

    func body(content: Content) -> some View {
        if let handler = onSelect ?? environmentHandler {
            content.contextMenu {
                EventContextMenuItems(
                    viewModel: viewModel,
                    showsDetailsAction: showsDetailsAction,
                    onSelect: { handler(.contextAction($0)) }
                )
            }
        } else {
            content
        }
    }
}

public extension View {
    func eventCardContextMenu(
        viewModel: EventViewModel,
        showsDetailsAction: Bool = true,
        onSelect: EventActionHandler? = nil
    ) -> some View {
        modifier(
            EventCardContextMenuModifier(
                viewModel: viewModel,
                showsDetailsAction: showsDetailsAction,
                onSelect: onSelect
            )
        )
    }
}

// MARK: - Native swipe list (UITableView-style)

public struct EventSwipeableRowsList<Row: View>: View {
    private let events: [EventViewModel]
    private let rowHeight: CGFloat
    private let onAction: EventActionHandler
  private let row: (EventViewModel) -> Row

    public init(
        events: [EventViewModel],
        rowHeight: CGFloat = 112,
        onAction: @escaping EventActionHandler,
        @ViewBuilder row: @escaping (EventViewModel) -> Row
    ) {
        self.events = events
        self.rowHeight = rowHeight
        self.onAction = onAction
        self.row = row
    }

    public var body: some View {
        List {
            ForEach(events) { event in
                row(event)
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        EventFavoriteSwipeAction(viewModel: event, onAction: onAction)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        EventCalendarSwipeAction(viewModel: event, onAction: onAction)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .environment(\.defaultMinListRowHeight, 1)
        .frame(height: listHeight)
    }

    private var listHeight: CGFloat {
        guard !events.isEmpty else { return 0 }
        return CGFloat(events.count) * rowHeight
    }
}

private struct EventFavoriteSwipeAction: View {
    @ObservedObject var viewModel: EventViewModel
    @ObservedObject private var favoriteState: FavoriteHeartButtonViewModel
    let onAction: EventActionHandler

    init(viewModel: EventViewModel, onAction: @escaping EventActionHandler) {
        self.viewModel = viewModel
        self.onAction = onAction
        _favoriteState = ObservedObject(wrappedValue: viewModel.favoriteHeartButtonViewModel)
    }

    var body: some View {
        Button {
            onAction(.contextAction(.favorite(viewModel.eventId)))
        } label: {
            Label(
                favoriteState.isFavorite ? "Убрать" : "В избранное",
                systemImage: favoriteState.isFavorite ? "heart.slash" : "heart"
            )
        }
        .tint(Color(uiColor: Colors.favorite))
    }
}

private struct EventCalendarSwipeAction: View {
    @ObservedObject var viewModel: EventViewModel
    @ObservedObject private var calendarState: EventCalendarToggleViewModel
    let onAction: EventActionHandler

    init(viewModel: EventViewModel, onAction: @escaping EventActionHandler) {
        self.viewModel = viewModel
        self.onAction = onAction
        _calendarState = ObservedObject(wrappedValue: viewModel.calendarToggleViewModel)
    }

    var body: some View {
        Button {
            onAction(.contextAction(.calendar(viewModel)))
        } label: {
            Label(
                calendarState.isInCalendar ? "Удалить" : "В календарь",
                systemImage: calendarState.isInCalendar ? "calendar.badge.minus" : "calendar.badge.plus"
            )
        }
        .tint(.blue)
    }
}
