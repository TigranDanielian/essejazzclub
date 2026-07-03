//
//  ScheduleTabNavigating.swift
//  ScheduleFeature
//

import SharedInfrastructure

/// Абстракция навигации вкладки «Афиша»: слой UI опирается на протокол, а не на конкретный роутер.
@MainActor
public protocol ScheduleTabNavigating: EventDetailRoutePresenting {
    func presentFilter(presentation: NavigationPresentationStyle)
}

extension ScheduleNavigationRouter: ScheduleTabNavigating {}
