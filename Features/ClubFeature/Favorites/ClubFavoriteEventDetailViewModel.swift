//
//  ClubFavoriteEventDetailViewModel.swift
//  ClubFeature
//

import Combine
import Foundation
import Services
import Core
import SharedInfrastructure

/// Состояние и побочные эффекты деталки избранного концерта (обзор по слотам или конкретный слот).
@MainActor
final class ClubFavoriteEventDetailViewModel: ObservableObject {
    let dependencies: ClubScreenDependencies
    private let clubScreen: ClubScreenViewModel
    let occurrenceIdentifier: String
    let mode: ClubNavigationRouter.FavoriteEventDetailMode

    /// `nil`, пока нет модели в кэше по `occurrenceIdentifier`.
    @Published private(set) var eventViewModel: EventViewModel?

    /// Тап по строке «Ближайшие даты» в режиме обзора; в режиме слота — `nil`.
    var onSelectUpcomingOccurrence: ((String) -> Void)? = nil

    private var cancellables = Set<AnyCancellable>()

    /// Снимок событий для списка ближайших дат (только в `.overview`).
    private var events: [EventModel] = []

    init(
        dependencies: ClubScreenDependencies,
        clubScreen: ClubScreenViewModel,
        occurrenceIdentifier: String,
        mode: ClubNavigationRouter.FavoriteEventDetailMode
    ) {
        self.dependencies = dependencies
        self.clubScreen = clubScreen
        self.occurrenceIdentifier = occurrenceIdentifier
        self.mode = mode

        switch mode {
        case .overview:
            onSelectUpcomingOccurrence = { [weak self] id in
                self?.clubScreen.presentRoute(
                    .favoriteEventDetail(occurrenceIdentifier: id, mode: .slot),
                    presentation: .push
                )
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

    var detailDisplayOptions: EventDetailDisplayOptions {
        mode == .overview ? .clubFavoriteEventOverview : .default
    }

    var upcomingOccurrences: [EventDetailUpcomingOccurrence]? {
        guard mode == .overview,
              let model = events.first(where: { eventOccurrenceIdentifier(for: $0) == occurrenceIdentifier })
        else { return nil }
        let rows = FavoriteEventSchedule.allDetailUpcomingOccurrences(forEventId: model.id, in: events)
        return rows.isEmpty ? nil : rows
    }

    func makeEventActionHandler() -> EventActionHandler {
        { [weak self] action in
            guard let self else { return }
            applyEventActionParts(
                action,
                applyNavigation: { nav in
                    switch nav {
                    case .dismiss:
                        self.clubScreen.popNavigation()
                    case .onMusicianDetails(let musician):
                        self.clubScreen.presentRoute(.musicianDetail(musician), presentation: .push)
                    case .onEventDetails(let vm):
                        self.clubScreen.presentRoute(
                            .favoriteEventDetail(occurrenceIdentifier: vm.occurrenceIdentifier, mode: .slot),
                            presentation: .push
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
        switch type {
        case .calendar(let viewModel):
            dependencies.calendarCoordinator.handleAction(with: viewModel)
        case .favorite(let id):
            dependencies.favoritesStorage.toggleState(forValue: id, forKey: .events)
        case .share(let viewModel):
            EventShareCoordinator.share(viewModel)
        case .details(_):
            break
        }
    }
}
