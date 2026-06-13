//
//  RootView+Routing.swift
//  EsseJazzClub
//

import Services
import SharedInfrastructure

extension RootView {
    func handleContextAction(_ type: EventContextButtonType) {
        EventContextActionHandler.handle(
            type,
            favoritesStorage: container.favoritesStorage,
            calendarCoordinator: container.calendarCoordinator
        )
    }
}
