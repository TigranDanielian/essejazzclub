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
        case eventDetail(EventViewModel, heroTransitionSourceID: String?)
        case musicianDetail(MusicianViewModel)
        case bookmarkedEventDetail(occurrenceIdentifier: String, mode: FavoriteEventDetailMode)

        public var id: String {
            switch self {
            case .eventDetail(let viewModel, let sourceID):
                return "home-event-\(viewModel.occurrenceIdentifier)-\(sourceID ?? "plain")"
            case .musicianDetail(let viewModel):
                return "home-musician-\(viewModel.musicianId)"
            case .bookmarkedEventDetail(let oid, let mode):
                return "home-bookmark-detail-\(oid)-\(mode.rawValue)"
            }
        }
    }

    public override init() {
        super.init()
    }

    public func applyEventNavigation(_ action: EventNavigationAction) {
        switch action {
        case .onEventDetails(let eventViewModel, let heroTransitionSourceID):
            presentEventDetail(viewModel: eventViewModel, heroTransitionSourceID: heroTransitionSourceID)
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
        case .favorite:
            break
        }
    }

    public func presentEventDetail(
        viewModel: EventViewModel,
        heroTransitionSourceID: String?,
        presentation: NavigationPresentationStyle = .push
    ) {
        present(route: .eventDetail(viewModel, heroTransitionSourceID: heroTransitionSourceID), presentation: presentation)
    }

    public func presentMusicianDetail(viewModel: MusicianViewModel) {
        present(route: .musicianDetail(viewModel), presentation: .push)
    }

    public func presentMusicianDetail(viewModel: MusicianViewModel, presentation: NavigationPresentationStyle) {
        present(route: .musicianDetail(viewModel), presentation: presentation)
    }

    public func presentBookmarkedEventOverview(occurrenceIdentifier: String) {
        present(
            route: .bookmarkedEventDetail(occurrenceIdentifier: occurrenceIdentifier, mode: .overview),
            presentation: .push
        )
    }
}

public enum HomeScreenAction {
    case event(EventAction)
    case musician(MusicianAction)
}
