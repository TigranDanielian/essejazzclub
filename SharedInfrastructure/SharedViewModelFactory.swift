//
//  SharedViewModelFactory.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 02.12.2025.
//

import Foundation
import Services
import Core
import Combine

/// Отдельный кэш по варианту карточки: Главная и Афиша не делят один `EventViewModel` с разными `hasContextMenu` / `hasDate`.
private struct EventViewModelCacheKey: Hashable {
    let occurrenceIdentifier: String
    let hasContextMenu: Bool
    let hasDate: Bool
}

public final class SharedViewModelFactory: @preconcurrency ViewModelFactory {
    private let musiaciansService: MusiciansService
    private let favoriteStorage: FavoritesStorage<String>
    private let calendarEventsManager: CalendarEventsManager
    private let imageLoader: AsyncImageLoader
    private var musiciansProvider: MusiciansProvider?

    private var eventViewModels: [EventViewModelCacheKey: EventViewModel] = [:]
    private var musicianViewModels: [Int: MusicianViewModel] = [:]
    
    public init(
        musiaciansService: MusiciansService,
        favoriteStorage: FavoritesStorage<String>,
        calendarEventsManager: CalendarEventsManager,
        imageLoader: @escaping AsyncImageLoader
    ) {
        self.musiaciansService = musiaciansService
        self.favoriteStorage = favoriteStorage
        self.calendarEventsManager = calendarEventsManager
        self.imageLoader = imageLoader
        self.musiciansProvider = makeMusiciansProvider()
    }
    
    @MainActor
    public func produce(unit: ViewModelUnit) -> any ObservableObject {
        switch unit {
        case .event(let hasContextMenu, let hasDate, let model):
            let key = EventViewModelCacheKey(
                occurrenceIdentifier: eventOccurrenceIdentifier(for: model),
                hasContextMenu: hasContextMenu,
                hasDate: hasDate
            )
            if let cached = eventViewModels[key] {
                return cached
            }
            let created = EventViewModel(
                model: model,
                hasContextMenu: hasContextMenu,
                withDate: hasDate,
                imageLoader: imageLoader,
                favoritesStorage: favoriteStorage,
                calendarEventsManager: calendarEventsManager,
                musiciansProvider: musiciansProvider
            )
            eventViewModels[key] = created
            return created
            
        case .musician(let musician):
            if let cachedViewModel = musicianViewModels[musician.id] {
                return cachedViewModel
            }
            
            let viewModel = MusicianViewModel(model: musician, imageLoader: imageLoader, favoritesStorage: favoriteStorage)
            musicianViewModels[musician.id] = viewModel
            
            return viewModel
        }
    }
    
    private func makeMusiciansProvider() -> MusiciansProvider {
        { [weak self] eventId in
            guard let self else {
                return Just([]).eraseToAnyPublisher()
            }
            return self.musiaciansService.forEvent(id: eventId)
                .receive(on: DispatchQueue.main)
                .flatMap { [weak self] musicians -> AnyPublisher<[MusicianViewModel], Never> in
                    guard let self else {
                        return Just([]).eraseToAnyPublisher()
                    }
                    return Future { promise in
                        Task { @MainActor in
                            let viewModels = musicians.map { musician in
                                self.produce(unit: .musician(musician)) as! MusicianViewModel
                            }
                            promise(.success(viewModels))
                        }
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}
