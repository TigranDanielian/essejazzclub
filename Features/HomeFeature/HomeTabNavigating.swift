//
//  HomeTabNavigating.swift
//  HomeFeature
//

import SharedInfrastructure

/// Абстракция навигации вкладки «Главная»: слой UI опирается на протокол, а не на конкретный роутер.
@MainActor
public protocol HomeTabNavigating: EventDetailRoutePresenting {
    func presentBookmarkedEventOverview(occurrenceIdentifier: String)
}

extension HomeNavigationRouter: HomeTabNavigating {}
