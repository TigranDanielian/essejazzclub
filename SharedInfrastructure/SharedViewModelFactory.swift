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

public final class SharedViewModelFactory: @preconcurrency ViewModelFactory {
    private let eventsService: EventsService
    private let musiaciansService: MusiciansService
    private let favoriteStorage: FavoritesStorage<String>
    private let imageLoader: AsyncImageLoader
    private var musiciansProvider: MusiciansProvider?

    private var eventViewModels: [String: EventViewModel] = [:]
    private var musicianViewModels: [Int: MusicianViewModel] = [:]
    
    public init(
        eventsService: EventsService,
        musiaciansService: MusiciansService,
        favoriteStorage: FavoritesStorage<String>,
        imageLoader: @escaping AsyncImageLoader
    ) {
        self.eventsService = eventsService
        self.musiaciansService = musiaciansService
        self.favoriteStorage = favoriteStorage
        self.imageLoader = imageLoader
        self.musiciansProvider = makeMusiciansProvider()
    }
    
    @MainActor
    public func produce(unit: ViewModelUnit) -> any ObservableObject {
        switch unit {
        case .event(let hasContextMenu, let hasDate, let model):
            let key = eventOccurrenceIdentifier(for: model)
            if let cached = eventViewModels[key] {
                cached.hasContextMenu = hasContextMenu
                cached.hasDate = hasDate
                return cached
            }
            let created = EventViewModel(
                model: model,
                hasContextMenu: hasContextMenu,
                withDate: hasDate,
                imageLoader: imageLoader,
                favoritesStorage: favoriteStorage,
                musiciansProvider: musiciansProvider
            )
            eventViewModels[key] = created
            return created
            
        case .musician(let musician):
            if let cachedViewModel = musicianViewModels[musician.id] {
                return cachedViewModel
            }
            
            let viewModel = MusicianViewModel(model: musician, imageLoader: imageLoader)
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

    @MainActor
    public func cachedEventViewModelForNavigation(forOccurrenceIdentifier identifier: String) -> EventViewModel? {
        eventViewModels[identifier]
    }

    @MainActor
    public func cachedMusicianViewModelForNavigation(for musicianId: Int) -> MusicianViewModel? {
        musicianViewModels[musicianId]
    }

    @MainActor
    public func retainEventViewModelForNavigation(_ viewModel: EventViewModel) {
        eventViewModels[viewModel.occurrenceIdentifier] = viewModel
    }

    @MainActor
    public func retainMusicianViewModelForNavigation(_ viewModel: MusicianViewModel) {
        musicianViewModels[viewModel.musicianId] = viewModel
    }

    @MainActor
    public func synchronizeNavigationCaches(allowedOccurrenceIdentifiers: Set<String>, allowedMusicianIds: Set<Int>) {
        eventViewModels = eventViewModels.filter { allowedOccurrenceIdentifiers.contains($0.key) }
        musicianViewModels = musicianViewModels.filter { allowedMusicianIds.contains($0.key) }
    }
}
