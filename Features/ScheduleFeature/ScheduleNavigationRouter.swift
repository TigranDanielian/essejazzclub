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
        case eventDetail(EventViewModel, heroTransitionSourceID: String?)
        case musicianDetail(MusicianViewModel)
        case filter

        public var id: String {
            switch self {
            case .eventDetail(let viewModel, let sourceID):
                return "schedule-event-\(viewModel.occurrenceIdentifier)-\(sourceID ?? "plain")"
            case .musicianDetail(let viewModel):
                return "schedule-musician-\(viewModel.musicianId)"
            case .filter:
                return "schedule-filter"
            }
        }
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
