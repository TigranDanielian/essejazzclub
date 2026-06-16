//
//  ClubFavoriteEventDetailHost.swift
//  ClubFeature
//

import SwiftUI
import SharedInfrastructure

/// Оболочка над общим `FavoriteEventDetailHost` с навигацией через `ClubScreenViewModel`.
struct ClubFavoriteEventDetailHost: View {
    let occurrenceIdentifier: String
    let mode: FavoriteEventDetailMode
    @ObservedObject var clubScreen: ClubScreenViewModel

    init(occurrenceIdentifier: String, mode: FavoriteEventDetailMode, clubScreen: ClubScreenViewModel) {
        self.occurrenceIdentifier = occurrenceIdentifier
        self.mode = mode
        self.clubScreen = clubScreen
    }

    var body: some View {
        FavoriteEventDetailHost(
            occurrenceIdentifier: occurrenceIdentifier,
            mode: mode,
            dependencies: clubScreen.dependencies.favoriteEventDetailDependencies,
            navigation: clubScreen
        )
    }
}

extension ClubScreenDependencies {
    var favoriteEventDetailDependencies: FavoriteEventDetailDependencies {
        FavoriteEventDetailDependencies(
            eventsService: eventsService,
            favoritesStorage: favoritesStorage,
            viewModelFactory: viewModelFactory,
            uiFactory: uiFactory,
            calendarCoordinator: calendarCoordinator
        )
    }
}

extension ClubScreenViewModel: FavoriteEventDetailNavigating {
    public func dismissFavoriteEventDetail() {
        popNavigation()
    }

    public func presentMusicianDetail(_ musician: MusicianViewModel) {
        presentRoute(.musicianDetail(musician), presentation: .push)
    }

    public func presentFavoriteEventSlotDetail(occurrenceIdentifier: String) {
        presentRoute(
            .favoriteEventDetail(occurrenceIdentifier: occurrenceIdentifier, mode: .slot),
            presentation: .push
        )
    }
}
