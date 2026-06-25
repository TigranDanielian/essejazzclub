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

@MainActor
public final class SharedViewModelFactory: ViewModelFactory {
    private let musiciansService: MusiciansService
    private let favoritesStorage: FavoritesStorage<String>
    private let calendarEventsManager: CalendarEventsManager
    private let imageLoader: AsyncImageLoader
    private var musiciansProvider: MusiciansProvider?

    private var eventViewModels: [EventViewModelCacheKey: EventViewModel] = [:]
    private var musicianViewModels: [Int: MusicianViewModel] = [:]

    public nonisolated init(
        musiciansService: MusiciansService,
        favoritesStorage: FavoritesStorage<String>,
        calendarEventsManager: CalendarEventsManager,
        imageLoader: @escaping AsyncImageLoader
    ) {
        self.musiciansService = musiciansService
        self.favoritesStorage = favoritesStorage
        self.calendarEventsManager = calendarEventsManager
        self.imageLoader = imageLoader
        self.musiciansProvider = Self.makeMusiciansProvider(
            musiciansService: musiciansService,
            makeViewModel: { [weak self] musician in
                self?.produce(unit: .musician(musician)) as? MusicianViewModel
            }
        )
    }

    public func produce(unit: ViewModelUnit) -> any ObservableObject {
        switch unit {
        case .event(let hasContextMenu, let hasDate, let hasPrice, let model):
            let key = EventViewModelCacheKey(
                occurrenceIdentifier: eventOccurrenceIdentifier(for: model),
                hasContextMenu: hasContextMenu,
                hasDate: hasDate
            )
            if let cached = eventViewModels[key] {
                cached.replaceModel(model)
                return cached
            }
            let created = EventViewModel(
                model: model,
                hasContextMenu: hasContextMenu,
                withDate: hasDate,
                withPrice: hasPrice,
                imageLoader: imageLoader,
                favoritesStorage: favoritesStorage,
                calendarEventsManager: calendarEventsManager,
                musiciansProvider: musiciansProvider
            )
            eventViewModels[key] = created
            return created

        case .musician(let musician):
            if let cachedViewModel = musicianViewModels[musician.id] {
                cachedViewModel.replaceModel(musician)
                return cachedViewModel
            }

            let viewModel = MusicianViewModel(
                model: musician,
                imageLoader: imageLoader,
                favoritesStorage: favoritesStorage
            )
            musicianViewModels[musician.id] = viewModel

            return viewModel
        }
    }

    private nonisolated static func makeMusiciansProvider(
        musiciansService: MusiciansService,
        makeViewModel: @escaping @MainActor (Musician) -> MusicianViewModel?
    ) -> MusiciansProvider {
        { eventId in
            musiciansService.forEvent(id: eventId)
                .flatMap { musicians -> AnyPublisher<[MusicianViewModel], Never> in
                    Future { promise in
                        Task { @MainActor in
                            let viewModels = musicians.compactMap { makeViewModel($0) }
                            promise(.success(viewModels))
                        }
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}
