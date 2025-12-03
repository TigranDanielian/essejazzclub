//
//  SharedViewModelFactory.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 02.12.2025.
//

import Foundation
import Services
import Core

public final class SharedViewModelFactory: @preconcurrency ViewModelFactory {
    private let eventsService: EventsService
    private let favoriteStorage: FavoritesStorage<String>
    private let imageLoader: AsyncImageLoader
    
    public init(
        eventsService: EventsService,
        favoriteStorage: FavoritesStorage<String>,
        imageLoader: @escaping AsyncImageLoader
    ) {
        self.eventsService = eventsService
        self.favoriteStorage = favoriteStorage
        self.imageLoader = imageLoader
    }
    
    @MainActor
    public func produce(unit: ViewModelUnit) -> any ObservableObject {
        switch unit {
        case .event(let hasContextMenu, let hasDate, let mdoel):
            return EventViewModel(model: mdoel, hasContextMenu: hasContextMenu, withDate: hasDate, imageLoader: imageLoader, favoritesStorage: favoriteStorage)
        }
    }
}
