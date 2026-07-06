//
//  HomeFavoriteEventDetailHost.swift
//  HomeFeature
//

import SwiftUI
import SharedInfrastructure

public typealias HomeFavoriteEventDetailDependencies = FavoriteEventDetailDependencies

public struct HomeFavoriteEventDetailHost: View {
    let occurrenceIdentifier: String
    let mode: FavoriteEventDetailMode
    let dependencies: FavoriteEventDetailDependencies
    let router: HomeNavigationRouter

    public init(
        occurrenceIdentifier: String,
        mode: FavoriteEventDetailMode,
        dependencies: FavoriteEventDetailDependencies,
        router: HomeNavigationRouter
    ) {
        self.occurrenceIdentifier = occurrenceIdentifier
        self.mode = mode
        self.dependencies = dependencies
        self.router = router
    }

    public var body: some View {
        FavoriteEventDetailHost(
            occurrenceIdentifier: occurrenceIdentifier,
            mode: mode,
            dependencies: dependencies,
            navigation: router
        )
    }
}

extension HomeNavigationRouter: FavoriteEventDetailNavigating {
    public func dismissFavoriteEventDetail() {
        dismissPresentedOrPop()
    }

    public func presentMusicianDetail(
        _ musician: MusicianViewModel,
        heroTransitionSourceID: String?
    ) {
        present(
            route: .musicianDetail(musician, heroTransitionSourceID: heroTransitionSourceID),
            presentation: .push
        )
    }

    public func presentFavoriteEventSlotDetail(occurrenceIdentifier: String) {
        present(
            route: .bookmarkedEventDetail(occurrenceIdentifier: occurrenceIdentifier, mode: .slot),
            presentation: .push
        )
    }
}
