//
//  FavoriteEventDetailViewModel.swift
//  SharedInfrastructure
//

import Combine
import Foundation
import Services
import Core

@MainActor
public final class FavoriteEventDetailViewModel: ObservableObject {
    public let dependencies: FavoriteEventDetailDependencies
    private weak var navigation: FavoriteEventDetailNavigating?
    public let occurrenceIdentifier: String
    public let mode: FavoriteEventDetailMode

    @Published public private(set) var eventViewModel: EventViewModel?
    public var onSelectUpcomingOccurrence: ((String) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private var events: [EventModel] = []

    public init(
        dependencies: FavoriteEventDetailDependencies,
        navigation: FavoriteEventDetailNavigating,
        occurrenceIdentifier: String,
        mode: FavoriteEventDetailMode
    ) {
        self.dependencies = dependencies
        self.navigation = navigation
        self.occurrenceIdentifier = occurrenceIdentifier
        self.mode = mode

        switch mode {
        case .overview:
            onSelectUpcomingOccurrence = { [weak navigation] id in
                navigation?.presentFavoriteEventSlotDetail(occurrenceIdentifier: id)
            }
        case .slot:
            onSelectUpcomingOccurrence = nil
        }

        dependencies.eventsService.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.events = state.events
                self.refreshEventViewModel()
            }
            .store(in: &cancellables)
    }

    public var detailDisplayOptions: EventDetailDisplayOptions {
        mode == .overview ? .favoriteEventOverview : .default
    }

    public var upcomingOccurrences: [EventDetailUpcomingOccurrence]? {
        guard mode == .overview,
              let model = events.first(where: { eventOccurrenceIdentifier(for: $0) == occurrenceIdentifier })
        else { return nil }
        let rows = FavoriteEventSchedule.allDetailUpcomingOccurrences(forEventId: model.id, in: events)
        return rows.isEmpty ? nil : rows
    }

    public func makeEventActionHandler() -> EventActionHandler {
        { [weak self] action in
            guard let self else { return }
            applyEventActionParts(
                action,
                applyNavigation: { nav in
                    switch nav {
                    case .dismiss:
                        self.navigation?.dismissFavoriteEventDetail()
                    case .onMusicianDetails(let musician):
                        self.navigation?.presentMusicianDetail(musician)
                    case .onEventDetails(let viewModel):
                        self.navigation?.presentFavoriteEventSlotDetail(
                            occurrenceIdentifier: viewModel.occurrenceIdentifier
                        )
                    case .onBuy:
                        break
                    }
                },
                handleContextButton: self.handleContext
            )
        }
    }

    private func refreshEventViewModel() {
        guard let model = events.first(where: { eventOccurrenceIdentifier(for: $0) == occurrenceIdentifier }) else {
            eventViewModel = nil
            return
        }
        eventViewModel = dependencies.viewModelFactory.produce(
            unit: .event(hasContextMenu: false, hasDate: true, model)
        ) as? EventViewModel
    }

    private func handleContext(_ type: EventContextButtonType) {
        EventContextActionHandler.handle(
            type,
            favoritesStorage: dependencies.favoritesStorage,
            calendarCoordinator: dependencies.calendarCoordinator
        )
    }
}
