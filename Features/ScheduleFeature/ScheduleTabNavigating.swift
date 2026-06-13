//
//  ScheduleTabNavigating.swift
//  ScheduleFeature
//

import Core
import SharedInfrastructure

/// Абстракция навигации вкладки «Афиша»: слой UI опирается на протокол, а не на конкретный роутер.
@MainActor
public protocol ScheduleTabNavigating: AnyObject {
    func applyEventNavigation(_ action: EventNavigationAction)
    func applyMusicianNavigation(_ action: MusicianAction)
    func presentFilter(presentation: NavigationPresentationStyle)
    func dismissPresentedOrPop()
}

extension ScheduleNavigationRouter: ScheduleTabNavigating {}

public extension ScheduleTabNavigating {
    func makeEventDetailActionHandler(contextHandler: @escaping (EventContextButtonType) -> Void) -> EventActionHandler {
        { action in
            applyEventActionParts(
                action,
                applyNavigation: { self.applyEventNavigation($0) },
                handleContextButton: contextHandler
            )
        }
    }

    func makeMusicianDetailActionHandler(favoritesStorage: FavoritesStorage<String>) -> MusicianActionHandler {
        { action in
            switch action {
            case .dismiss:
                self.dismissPresentedOrPop()
            case .favorite(let id):
                favoritesStorage.applyFavoriteContext(.musician(musicianId: id))
            }
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
