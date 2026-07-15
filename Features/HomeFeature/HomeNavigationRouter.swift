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
        case musicianDetail(MusicianViewModel, heroTransitionSourceID: String?)
        case bookmarkedEventDetail(occurrenceIdentifier: String, mode: FavoriteEventDetailMode)

        public var id: String {
            switch self {
            case .eventDetail(let viewModel, let sourceID):
                return "home-event-\(viewModel.occurrenceIdentifier)-\(sourceID ?? "plain")"
            case .musicianDetail(let viewModel, let sourceID):
                return "home-musician-\(viewModel.musicianId)-\(sourceID ?? "plain")"
            case .bookmarkedEventDetail(let oid, let mode):
                return "home-bookmark-detail-\(oid)-\(mode.rawValue)"
            }
        }
    }

    public override init() {
        super.init()
    }

    public override func deduplicationKey(for route: Route) -> String {
        switch route {
        case .eventDetail(let viewModel, _):
            return "event-\(viewModel.occurrenceIdentifier)"
        case .musicianDetail(let viewModel, _):
            return "musician-\(viewModel.musicianId)"
        case .bookmarkedEventDetail(let occurrenceIdentifier, let mode):
            return "event-\(occurrenceIdentifier)-\(mode.rawValue)"
        }
    }

    public func presentEventDetail(
        viewModel: EventViewModel,
        heroTransitionSourceID: String?,
        presentation: NavigationPresentationStyle = .push
    ) {
        present(route: .eventDetail(viewModel, heroTransitionSourceID: heroTransitionSourceID), presentation: presentation)
    }

    public func presentMusicianDetail(
        viewModel: MusicianViewModel,
        heroTransitionSourceID: String?,
        presentation: NavigationPresentationStyle = .push
    ) {
        present(
            route: .musicianDetail(viewModel, heroTransitionSourceID: heroTransitionSourceID),
            presentation: presentation
        )
    }

    public func presentMusicianDetail(viewModel: MusicianViewModel) {
        presentMusicianDetail(viewModel: viewModel, heroTransitionSourceID: nil, presentation: .push)
    }

    public func presentMusicianDetail(viewModel: MusicianViewModel, presentation: NavigationPresentationStyle) {
        presentMusicianDetail(viewModel: viewModel, heroTransitionSourceID: nil, presentation: presentation)
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
