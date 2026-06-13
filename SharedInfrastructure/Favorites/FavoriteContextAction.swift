//
//  FavoriteContextAction.swift
//  SharedInfrastructure
//

import Core

public enum FavoriteContextAction: Equatable {
    case event(eventId: String)
    case musician(musicianId: String)

    var storageKey: FavoritesStorageKey {
        switch self {
        case .event:
            return .events
        case .musician:
            return .musicians
        }
    }

    var value: String {
        switch self {
        case .event(let id), .musician(let id):
            return id
        }
    }
}

public extension FavoritesStorage where Value == String {
    func applyFavoriteContext(_ action: FavoriteContextAction) {
        toggleState(forValue: action.value, forKey: action.storageKey)
    }
}

public extension EventContextButtonType {
    var favoriteContextAction: FavoriteContextAction? {
        guard case .favorite(let id) = self else { return nil }
        return .event(eventId: id)
    }
}

public extension MusicianAction {
    var favoriteContextAction: FavoriteContextAction? {
        guard case .favorite(let id) = self else { return nil }
        return .musician(musicianId: id)
    }
}
