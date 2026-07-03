//
//  FavoriteEventDetailDependencies.swift
//  SharedInfrastructure
//

import Core
import Services

public struct FavoriteEventDetailDependencies {
    public let eventsService: EventsService
    public let favoritesStorage: FavoritesStorage<String>
    public let viewModelFactory: ViewModelFactory
    public let uiFactory: any UIFactory
    public let calendarCoordinator: EventCalendarCoordinator
    public let toastPresenter: ToastPresenter

    public init(
        eventsService: EventsService,
        favoritesStorage: FavoritesStorage<String>,
        viewModelFactory: ViewModelFactory,
        uiFactory: any UIFactory,
        calendarCoordinator: EventCalendarCoordinator,
        toastPresenter: ToastPresenter
    ) {
        self.eventsService = eventsService
        self.favoritesStorage = favoritesStorage
        self.viewModelFactory = viewModelFactory
        self.uiFactory = uiFactory
        self.calendarCoordinator = calendarCoordinator
        self.toastPresenter = toastPresenter
    }
}

@MainActor
public protocol FavoriteEventDetailNavigating: AnyObject {
    func dismissFavoriteEventDetail()
    func presentMusicianDetail(_ musician: MusicianViewModel)
    func presentFavoriteEventSlotDetail(occurrenceIdentifier: String)
}
