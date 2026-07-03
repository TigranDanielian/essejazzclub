//
//  ClubTabNavigating.swift
//  ClubFeature
//

import SharedInfrastructure

/// Абстракция навигации вкладки «Клуб»: слой UI опирается на протокол, а не на конкретный роутер.
@MainActor
public protocol ClubTabNavigating: EventDetailRoutePresenting {
    func presentClubRoute(_ route: ClubNavigationRouter.Route, presentation: NavigationPresentationStyle)
    func openHubRoute(_ route: ClubNavigationRouter.Route)
}

extension ClubNavigationRouter: ClubTabNavigating {
    public func presentClubRoute(
        _ route: Route,
        presentation: NavigationPresentationStyle = .push
    ) {
        present(route: route, presentation: presentation)
    }

    public func openHubRoute(_ route: Route) {
        present(route: route, presentation: .push)
    }

    public func presentEventDetail(
        viewModel: EventViewModel,
        heroTransitionSourceID: String?,
        presentation: NavigationPresentationStyle = .push
    ) {
        present(
            route: .favoriteEventDetail(
                occurrenceIdentifier: viewModel.occurrenceIdentifier,
                mode: .slot
            ),
            presentation: presentation
        )
    }

    public func presentMusicianDetail(
        viewModel: MusicianViewModel,
        presentation: NavigationPresentationStyle = .push
    ) {
        present(route: .musicianDetail(viewModel), presentation: presentation)
    }
}

extension ClubNavigationRouter: FavoriteEventDetailNavigating {
    public func dismissFavoriteEventDetail() {
        dismissPresentedOrPop()
    }

    public func presentMusicianDetail(_ musician: MusicianViewModel) {
        presentMusicianDetail(viewModel: musician, presentation: .push)
    }

    public func presentFavoriteEventSlotDetail(occurrenceIdentifier: String) {
        present(
            route: .favoriteEventDetail(occurrenceIdentifier: occurrenceIdentifier, mode: .slot),
            presentation: .push
        )
    }
}
