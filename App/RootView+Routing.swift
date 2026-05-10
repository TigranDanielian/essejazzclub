//
//  RootView+Routing.swift
//  EsseJazzClub
//

import Services
import SharedInfrastructure
import HomeFeature
import ScheduleFeature

extension RootView {
    func handleHomeAction(_ action: HomeScreenAction) {
        homeNavigationRouter.handle(action, contextHandler: handleContextAction(_:))
    }
    
    func handleScheduleAction(_ action: ScheduleScreenAction) {
        scheduleNavigationRouter.handle(action, contextHandler: handleContextAction(_:))
    }
    
    func handleContextAction(_ type: EventContextButtonType) {
        switch type {
        case .calendar(let viewModel):
            container.calendarCoordinator.handleAction(with: viewModel)
        case .favorite(let id):
            container.favoritesStorage.toggleState(forValue: id, forKey: .events)
        case .share:
            break
        case .details(_):
            break
        }
    }
}
