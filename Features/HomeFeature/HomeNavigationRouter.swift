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
            case .eventDetail(let viewModel):
                return "home-event-\(viewModel.occurrenceIdentifier)"
            case .musicianDetail(let viewModel):
                return "home-musician-\(viewModel.musicianId)"
            }
        }
    }

    public override init() {
        super.init()
    }

    public func applyEventNavigation(_ action: EventNavigationAction) {
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

    public func applyMusicianNavigation(_ action: MusicianAction) {
        switch action {
        case .dismiss:
            dismissPresentedOrPop()
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
