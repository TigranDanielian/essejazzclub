//
//  EventContextActionHandler.swift
//  SharedInfrastructure
//

import Core

@MainActor
public enum EventContextActionHandler {
    public static func handle(
        _ type: EventContextButtonType,
        favoritesStorage: FavoritesStorage<String>,
        calendarCoordinator: EventCalendarCoordinator
    ) {
        switch type {
        case .calendar(let viewModel):
            calendarCoordinator.handleAction(with: viewModel)
        case .favorite(let id):
            favoritesStorage.applyFavoriteContext(.event(eventId: id))
        case .share(let viewModel):
            EventShareCoordinator.share(viewModel)
        case .details:
            break
        }
    }
}
