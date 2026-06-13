//
//  RootView+Routing.swift
//  EsseJazzClub
//

import Services
import SharedInfrastructure

extension RootView {
    func handleContextAction(_ type: EventContextButtonType) {
        switch type {
        case .calendar(let viewModel):
            container.calendarCoordinator.handleAction(with: viewModel)
        case .favorite(let id):
            container.favoritesStorage.toggleState(forValue: id, forKey: .events)
        case .share(let viewModel):
            EventShareCoordinator.share(viewModel)
        case .details(_):
            break
        }
    }
}
