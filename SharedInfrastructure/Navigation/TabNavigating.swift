//
//  TabNavigating.swift
//  SharedInfrastructure
//

import Core

/// Базовая навигация вкладки: закрытие модалки или pop стека.
@MainActor
public protocol TabNavigating: AnyObject {
    func dismissPresentedOrPop()
}

/// Навигация по событиям и музыкантам + фабрики обработчиков для экранов деталей.
@MainActor
public protocol EventTabNavigating: TabNavigating {
    func applyEventNavigation(_ action: EventNavigationAction)
    func applyMusicianNavigation(_ action: MusicianAction)
}

public extension EventTabNavigating {
    func makeEventDetailActionHandler(
        contextHandler: @escaping (EventContextButtonType) -> Void
    ) -> EventActionHandler {
        { action in
            applyEventActionParts(
                action,
                applyNavigation: { self.applyEventNavigation($0) },
                handleContextButton: contextHandler
            )
        }
    }

    func makeMusicianDetailActionHandler(
        favoritesStorage: FavoritesStorage<String>,
        toastPresenter: ToastPresenter
    ) -> MusicianActionHandler {
        { action in
            switch action {
            case .dismiss:
                self.dismissPresentedOrPop()
            case .favorite(let id):
                let wasFavorite = favoritesStorage.isFavorite(id, forKey: .events)
                favoritesStorage.applyFavoriteContext(.musician(musicianId: id))
                toastPresenter.show(
                    wasFavorite ? "Удалено из избранного" : "Добавлено в избранное"
                )
            }
        }
    }
}

/// Роутеры с маршрутами деталки события / музыканта — общая реализация `apply*`.
@MainActor
public protocol EventDetailRoutePresenting: EventTabNavigating {
    func presentEventDetail(
        viewModel: EventViewModel,
        heroTransitionSourceID: String?,
        presentation: NavigationPresentationStyle
    )
    func presentMusicianDetail(
        viewModel: MusicianViewModel,
        presentation: NavigationPresentationStyle
    )
}

public extension EventDetailRoutePresenting {
    func presentEventDetail(
        viewModel: EventViewModel,
        heroTransitionSourceID: String?
    ) {
        presentEventDetail(
            viewModel: viewModel,
            heroTransitionSourceID: heroTransitionSourceID,
            presentation: .push
        )
    }

    func presentMusicianDetail(viewModel: MusicianViewModel) {
        presentMusicianDetail(viewModel: viewModel, presentation: .push)
    }

    func applyEventNavigation(_ action: EventNavigationAction) {
        switch action {
        case .onEventDetails(let eventViewModel, let heroTransitionSourceID):
            presentEventDetail(
                viewModel: eventViewModel,
                heroTransitionSourceID: heroTransitionSourceID,
                presentation: .push
            )
        case .onMusicianDetails(let musicianViewModel):
            presentMusicianDetail(viewModel: musicianViewModel, presentation: .push)
        case .dismiss:
            dismissPresentedOrPop()
        case .onBuy:
            break
        }
    }

    func applyMusicianNavigation(_ action: MusicianAction) {
        switch action {
        case .dismiss:
            dismissPresentedOrPop()
        case .favorite:
            break
        }
    }
}
