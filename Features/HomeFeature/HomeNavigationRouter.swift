//
//  HomeNavigationRouter.swift
//  HomeFeature
//

import SwiftUI
import SharedInfrastructure

/// Навигация только для вкладки «Главная»: локальный стек и модалки модуля Home.
@MainActor
public final class HomeNavigationRouter: StackNavigationRouter<HomeNavigationRouter.Route> {
    public enum Route: Hashable, Identifiable {
        case eventDetail(EventViewModel)
        case musicianDetail(MusicianViewModel)

        public var id: String {
            switch self {
            case .eventDetail(let occurrenceIdentifier):
                return "home-event-\(occurrenceIdentifier)"
            case .musicianDetail(let musicianId):
                return "home-musician-\(musicianId)"
            }
        }
    }

    public override init() {
        super.init()
    }
    
    public func handle( _ action: HomeScreenAction, contextHandler: @escaping (EventContextButtonType) -> Void) {
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
        }
    }

    public func presentEventDetail(viewModel: EventViewModel, presentation: NavigationPresentationStyle = .push) {
        present(route: .eventDetail(viewModel), presentation: presentation)
    }

    public func presentMusicianDetail(viewModel: MusicianViewModel, presentation: NavigationPresentationStyle = .push) {
        present(route: .musicianDetail(viewModel), presentation: presentation)
    }
}

public enum HomeScreenAction {
    case event(EventAction)
    case musician(MusicianAction)
}
