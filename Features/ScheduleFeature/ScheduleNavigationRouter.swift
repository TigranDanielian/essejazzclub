//
//  ScheduleNavigationRouter.swift
//  ScheduleFeature
//

import SwiftUI
import SharedInfrastructure

/// Навигация только для вкладки «Афиша»: локальный стек, модалки и фильтр модуля Schedule.
@MainActor
public final class ScheduleNavigationRouter: StackNavigationRouter<ScheduleNavigationRouter.Route> {
    public enum Route: Hashable, Identifiable {
        case eventDetail(EventViewModel)
        case musicianDetail(MusicianViewModel)
        case filter

        public var id: String {
            switch self {
            case .eventDetail(let id):
                return "schedule-event-\(id)"
            case .musicianDetail(let id):
                return "schedule-musician-\(id)"
            case .filter:
                return "schedule-filter"
            }
        }
    }
    
    public func handle( _ action: ScheduleScreenAction, contextHandler: @escaping (EventContextButtonType) -> Void) {
        switch action {
        case .event(let action):
            switch action {
            case .contextAction(let action):
                if case .details(let viewModel) = action {
                    presentEventDetail(viewModel: viewModel)
                }
                contextHandler(action)
                
            case .navigation(let action):
                switch action {
                case .onEventDetails(let eventViewModel):
                    presentEventDetail(viewModel: eventViewModel)
                case .onMusicianDetails(let musicianViewModel):
                    presentMusicianDetail(viewModel: musicianViewModel)
                case .dismiss:
                    dismissPresentedOrPop()
                case .onBuy:
                    break
                }
            
            }
        case .musician(let action):
            switch action {
            case .dismiss:
                dismissPresentedOrPop()
            }
        case .filter:
            break
        }
    }

    public func presentEventDetail(viewModel: EventViewModel, presentation: NavigationPresentationStyle = .push) {
        present(route: .eventDetail(viewModel), presentation: presentation)
    }

    public func presentMusicianDetail(viewModel: MusicianViewModel, presentation: NavigationPresentationStyle = .push) {
        present(route: .musicianDetail(viewModel), presentation: presentation)
    }

    public func presentFilter(presentation: NavigationPresentationStyle = .sheet) {
        present(route: .filter, presentation: presentation)
    }
}

public enum ScheduleScreenAction {
    case event(EventAction)
    case musician(MusicianAction)
    case filter
}
