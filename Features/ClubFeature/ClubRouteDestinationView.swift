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

    /// Ветки маршрута имеют разные конкретные типы `View` + `produce` даёт `associatedtype` у `UIFactory` — без `AnyView` `switch` не компилируется.
    var body: some View {
        switch route {
        case .favorites:
            AnyView(ClubFavoritesScreen(viewModel: clubViewModel))
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
                            dependencies.favoritesStorage.applyFavoriteContext(.musician(musicianId: id))
                        }
                    })
                )
            )
        case .about:
            AnyView(ClubAboutDestinationView(contentService: dependencies.contentService))

        case .musicians:
            AnyView(
                ClubMusiciansScreen(
                    dependencies: ClubMusiciansScreenDependencies(
                        musiciansService: dependencies.musiciansService,
                        favoritesStorage: dependencies.favoritesStorage,
                        imageLoader: dependencies.imageLoader,
                        viewModelFactory: dependencies.viewModelFactory,
                        uiFactory: dependencies.uiFactory
                    ),
                    router: clubViewModel.router
                )
            )
        case .contacts:
            AnyView(ClubContactsScreen())
        case .giftShop:
            AnyView(
                ClubShopScreen(
                    dependencies: ClubShopScreenDependencies(
                        shopService: dependencies.shopService,
                        imageLoader: dependencies.imageLoader
                    )
                )
            )
        case .menu:
            AnyView(
                ClubMenuScreen(
                    dependencies: ClubMenuScreenDependencies(
                        contentService: dependencies.contentService,
                        imageLoader: dependencies.imageLoader
                    )
                )
            )
        }
    }
}
