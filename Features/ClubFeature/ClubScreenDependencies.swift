//
//  ClubScreenDependencies.swift
//  ClubFeature
//

import Combine
import Core
import Services
import SharedInfrastructure

/// Зависимости вкладки «Клуб» без привязки к таргету приложения (`AppContainer`).
public struct ClubScreenDependencies {
    public let eventsService: EventsService
    public let musiciansService: MusiciansService
    public let contentService: ContentService
    public let shopService: ShopService
    public let favoritesStorage: FavoritesStorage<String>
    public let imageLoader: ImageLoader
    public let viewModelFactory: ViewModelFactory
    public let uiFactory: any UIFactory
    public let calendarCoordinator: EventCalendarCoordinator
    public let toastPresenter: ToastPresenter

    public init(
        eventsService: EventsService,
        musiciansService: MusiciansService,
        contentService: ContentService,
        shopService: ShopService,
        favoritesStorage: FavoritesStorage<String>,
        imageLoader: ImageLoader,
        viewModelFactory: ViewModelFactory,
        uiFactory: any UIFactory,
        calendarCoordinator: EventCalendarCoordinator,
        toastPresenter: ToastPresenter
    ) {
        self.eventsService = eventsService
        self.musiciansService = musiciansService
        self.contentService = contentService
        self.shopService = shopService
        self.favoritesStorage = favoritesStorage
        self.imageLoader = imageLoader
        self.viewModelFactory = viewModelFactory
        self.uiFactory = uiFactory
        self.calendarCoordinator = calendarCoordinator
        self.toastPresenter = toastPresenter
    }
}
