//
//  ClubRouteDestinationView.swift
//  ClubFeature
//

import SwiftUI
import Core
import SharedInfrastructure

struct ClubRouteDestinationView: View {
    let route: ClubNavigationRouter.Route
    @ObservedObject var router: ClubNavigationRouter
    let dependencies: ClubScreenDependencies

    var body: some View {
        switch route {
        case .favorites:
            AnyView(ClubFavoritesScreen(router: router, dependencies: dependencies))
        case .favoriteEventDetail(let occurrenceIdentifier):
            AnyView(
                ClubFavoriteEventDetailHost(
                    occurrenceIdentifier: occurrenceIdentifier,
                    router: router,
                    dependencies: dependencies
                )
            )
        case .musicianDetail(let viewModel):
            AnyView(
                dependencies.uiFactory.produce(
                    unit: .musician(viewModel, { action in
                        switch action {
                        case .dismiss:
                            router.pop()
                        case .favorite(let id):
                            dependencies.favoritesStorage.toggleState(forValue: id, forKey: .musicians)
                        }
                    })
                )
            )
        case .about, .menu, .contacts, .musicians, .giftShop:
            AnyView(ClubSectionPlaceholderView(route: route))
        }
    }
}
