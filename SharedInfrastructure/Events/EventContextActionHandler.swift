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
        calendarCoordinator: EventCalendarCoordinator,
        toastPresenter: ToastPresenter
    ) {
        switch type {
        case .calendar(let viewModel):
            calendarCoordinator.handleAction(with: viewModel)
        case .favorite(let id):
            let wasFavorite = favoritesStorage.isFavorite(id, forKey: .events)
            favoritesStorage.applyFavoriteContext(.event(eventId: id))
            toastPresenter.show(
                wasFavorite ? "Удалено из избранного" : "Добавлено в избранное"
            )
        case .share(let viewModel):
            EventShareCoordinator.share(viewModel)
        case .details:
            break
        }
    }
}
