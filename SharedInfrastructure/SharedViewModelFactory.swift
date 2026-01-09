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
            return EventViewModel(model: model, hasContextMenu: hasContextMenu, withDate: hasDate, imageLoader: imageLoader, favoritesStorage: favoriteStorage, musiciansProvider: musiciansProvider)
        case .musician(let musician):
            return MusicianViewModel(model: musician, imageLoader: imageLoader)
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
