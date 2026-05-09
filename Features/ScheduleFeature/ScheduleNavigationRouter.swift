//
//  ScheduleNavigationRouter.swift
//  ScheduleFeature
//

import SwiftUI
import SharedInfrastructure

/// Навигация только для вкладки «Афиша»: локальный стек, модалки и фильтр модуля Schedule.
@MainActor
public final class ScheduleNavigationRouter: StackNavigationRouter<ScheduleNavigationRouter.Route>, EventOccurrenceRoutingCaches {
    public enum Route: Hashable, Identifiable {
        case eventDetail(String)
        case musicianDetail(Int)
        case filter

        public var id: String {
            switch self {
            case .eventDetail(let occurrenceIdentifier):
                return "schedule-event-\(occurrenceIdentifier)"
            case .musicianDetail(let musicianId):
                return "schedule-musician-\(musicianId)"
            case .filter:
                return "schedule-filter"
            }
        }
    }

    private var eventViewModelsForNavigation: [String: EventViewModel] = [:]
    private var musicianViewModelsForNavigation: [Int: MusicianViewModel] = [:]

    public override init() {
        super.init()
    }

    public func presentEventDetail(_ viewModel: EventViewModel, presentation: NavigationPresentationStyle = .push) {
        let occurrenceIdentifier = viewModel.occurrenceIdentifier
        eventViewModelsForNavigation[occurrenceIdentifier] = viewModel
        present(.eventDetail(occurrenceIdentifier), presentation: presentation)
    }

    public func presentMusicianDetail(_ viewModel: MusicianViewModel, presentation: NavigationPresentationStyle = .push) {
        let musicianId = viewModel.musicianId
        musicianViewModelsForNavigation[musicianId] = viewModel
        present(.musicianDetail(musicianId), presentation: presentation)
    }

    public func presentFilter(presentation: NavigationPresentationStyle = .sheet) {
        present(.filter, presentation: presentation)
    }

    public func cachedEventViewModel(forOccurrenceIdentifier identifier: String) -> EventViewModel? {
        eventViewModelsForNavigation[identifier]
    }

    public func cachedMusicianViewModel(for musicianId: Int) -> MusicianViewModel? {
        musicianViewModelsForNavigation[musicianId]
    }

    public override func synchronizeCaches() {
        let pathOccurrences = Set(path.compactMap { route -> String? in
            if case .eventDetail(let id) = route { return id }
            return nil
        })
        let modalOccurrences = Set(modalRoutes.compactMap { route -> String? in
            if case .eventDetail(let id) = route { return id }
            return nil
        })
        let allowedOccurrences = pathOccurrences.union(modalOccurrences)
        eventViewModelsForNavigation = eventViewModelsForNavigation.filter { allowedOccurrences.contains($0.key) }

        let pathMusicians = Set(path.compactMap { route -> Int? in
            if case .musicianDetail(let id) = route { return id }
            return nil
        })
        let modalMusicians = Set(modalRoutes.compactMap { route -> Int? in
            if case .musicianDetail(let id) = route { return id }
            return nil
        })
        let allowedMusicians = pathMusicians.union(modalMusicians)
        musicianViewModelsForNavigation = musicianViewModelsForNavigation.filter { allowedMusicians.contains($0.key) }
    }
}
