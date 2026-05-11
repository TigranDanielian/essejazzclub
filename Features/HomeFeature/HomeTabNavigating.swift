//
//  HomeTabNavigating.swift
//  HomeFeature
//

import SharedInfrastructure

/// Абстракция навигации вкладки «Главная»: слой UI опирается на протокол, а не на конкретный роутер.
@MainActor
public protocol HomeTabNavigating: AnyObject {
    func applyEventNavigation(_ action: EventNavigationAction)
    func applyMusicianNavigation(_ action: MusicianAction)
    func dismissPresentedOrPop()
}

extension HomeNavigationRouter: HomeTabNavigating {}

public extension HomeTabNavigating {
    /// Обработчик для `EventDetailView`: навигация → роутер, контекстные кнопки → снаружи.
    func makeEventDetailActionHandler(contextHandler: @escaping (EventContextButtonType) -> Void) -> EventActionHandler {
        { action in
            applyEventActionParts(
                action,
                applyNavigation: { self.applyEventNavigation($0) },
                handleContextButton: contextHandler
            )
        }
    }

    func makeMusicianDetailActionHandler(favoritesHandler: @escaping (String) -> Void) -> MusicianActionHandler {
        { action in
            switch action {
            case .dismiss:
                self.dismissPresentedOrPop()
            case .favorite(let id):
                favoritesHandler(id)
            }
        }
    }
}
