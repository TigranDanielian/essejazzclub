//
//  AppContainer.swift
//  Core
//
//  Created by Tigran Danielian on 30.05.2025.
//

import Foundation
import Services
import API
import Combine
import Core
import SharedInfrastructure

public final class AppContainer: ObservableObject {
    public let imageLoader: ImageLoader = ImageLoaderImpl(host: Config.imageBaseUrl)
    public let eventsService: EventsService
    public let musiciansService: MusiciansService
    public let contentService: ContentService
    public let shopService: ShopService
    public let favoritesStorage: FavoritesStorage<String> = .init()
    public let calendarEventsManager: CalendarEventsManager = CalendarEventsManager()
    public let toastPresenter = ToastPresenter()
    public let viewModelFactory: ViewModelFactory
    public let uiFactory: any UIFactory
    public var calendarCoordinator: EventCalendarCoordinator
    
    private var cancellables: Set<AnyCancellable> = []

    init(apiClient: ApiClient) {
        self.eventsService = EventsServiceImpl(apiClient: apiClient)
        self.musiciansService = MusiciansServiceImpl(apiClient: apiClient)
        self.contentService = ContentServiceImpl(apiClient: apiClient)
        self.shopService = ShopServiceImpl(apiClient: apiClient)
        
        self.viewModelFactory = SharedViewModelFactory(
            musiciansService: musiciansService,
            eventsService: eventsService,
            favoritesStorage: favoritesStorage,
            calendarEventsManager: calendarEventsManager,
            imageLoader: imageLoader.loadImage(path:)
        )
        
        self.uiFactory = SharedUIFactory(imageLoader: imageLoader)

        self.calendarCoordinator = EventCalendarCoordinator(
            calendarManager: calendarEventsManager,
            toastPresenter: toastPresenter
        )

        toastPresenter.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    public func loadEssentialData(onComplete: @escaping (Result<Void, Error>) -> Void) {
        Publishers
            .CombineLatest(
                eventsService.load(),
                musiciansService.load()
            )
            .combineLatest(
                contentService.load(),
                shopService.load()
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        print("✅ Completed essential data loading")
                        onComplete(.success(()))
                    case .failure(let error):
                        print("❌ Essential data loading failed: \(error.localizedDescription)")
                        onComplete(.failure(error))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}
