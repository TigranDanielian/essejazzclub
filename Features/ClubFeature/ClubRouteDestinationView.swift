//
//  ClubRouteDestinationView.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

struct ClubRouteDestinationView: View {
    let route: ClubNavigationRouter.Route
    @ObservedObject var clubViewModel: ClubScreenViewModel

    private var dependencies: ClubScreenDependencies { clubViewModel.dependencies }

    var body: some View {
        switch route {
        case .favorites:
            AnyView(ClubFavoritesScreen(screenModel: clubViewModel))
        case .favoriteEventDetail(let occurrenceIdentifier, let mode):
            AnyView(
                ClubFavoriteEventDetailHost(
                    occurrenceIdentifier: occurrenceIdentifier,
                    mode: mode,
                    clubScreen: clubViewModel
                )
            )
        case .musicianDetail(let musicianVM):
            AnyView(
                dependencies.uiFactory.produce(
                    unit: .musician(musicianVM, { action in
                        switch action {
                        case .dismiss:
                            clubViewModel.popNavigation()
                        case .favorite(let id):
                            dependencies.favoritesStorage.toggleState(forValue: id, forKey: .musicians)
                        }
                    })
                )
            )
        case .about:
            AnyView(ClubAboutDestinationView(contentService: dependencies.contentService))

        case .menu, .contacts, .musicians, .giftShop:
            AnyView(ClubSectionPlaceholderView(route: route))
        }
    }
}
