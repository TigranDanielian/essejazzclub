//
//  HomeFavoriteEventDetailHost.swift
//  HomeFeature
//

import Combine
import Foundation
import SwiftUI
import Core
import Services
import SharedInfrastructure

public struct HomeFavoriteEventDetailDependencies {
    public let eventsService: EventsService
    public let favoritesStorage: FavoritesStorage<String>
    public let viewModelFactory: ViewModelFactory
    public let uiFactory: any UIFactory
    public let calendarCoordinator: EventCalendarCoordinator

    public init(
        eventsService: EventsService,
        favoritesStorage: FavoritesStorage<String>,
        viewModelFactory: ViewModelFactory,
        uiFactory: any UIFactory,
        calendarCoordinator: EventCalendarCoordinator
    ) {
        self.eventsService = eventsService
        self.favoritesStorage = favoritesStorage
        self.viewModelFactory = viewModelFactory
        self.uiFactory = uiFactory
        self.calendarCoordinator = calendarCoordinator
    }
}

@MainActor
final class HomeFavoriteEventDetailViewModel: ObservableObject {
    let dependencies: HomeFavoriteEventDetailDependencies
    private weak var router: HomeNavigationRouter?
    let occurrenceIdentifier: String
    let mode: HomeNavigationRouter.FavoriteEventDetailMode

    @Published private(set) var eventViewModel: EventViewModel?
    var onSelectUpcomingOccurrence: ((String) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private var events: [EventModel] = []

    init(
        dependencies: HomeFavoriteEventDetailDependencies,
        router: HomeNavigationRouter,
        occurrenceIdentifier: String,
        mode: HomeNavigationRouter.FavoriteEventDetailMode
    ) {
        self.dependencies = dependencies
        self.router = router
        self.occurrenceIdentifier = occurrenceIdentifier
        self.mode = mode

        switch mode {
        case .overview:
            onSelectUpcomingOccurrence = { [weak self] id in
                self?.router?.present(
                    route: .bookmarkedEventDetail(occurrenceIdentifier: id, mode: .slot),
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
                        self.router?.dismissPresentedOrPop()
                    case .onMusicianDetails(let musician):
                        self.router?.present(route: .musicianDetail(musician), presentation: .push)
                    case .onEventDetails(let vm):
                        self.router?.present(
                            route: .bookmarkedEventDetail(occurrenceIdentifier: vm.occurrenceIdentifier, mode: .slot),
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

public struct HomeFavoriteEventDetailHost: View {
    @StateObject private var detail: HomeFavoriteEventDetailViewModel

    public init(
        occurrenceIdentifier: String,
        mode: HomeNavigationRouter.FavoriteEventDetailMode,
        dependencies: HomeFavoriteEventDetailDependencies,
        router: HomeNavigationRouter
    ) {
        _detail = StateObject(
            wrappedValue: HomeFavoriteEventDetailViewModel(
                dependencies: dependencies,
                router: router,
                occurrenceIdentifier: occurrenceIdentifier,
                mode: mode
            )
        )
    }

    public var body: some View {
        Group {
            if let eventVM = detail.eventViewModel {
                AnyView(
                    detail.dependencies.uiFactory.produce(
                        unit: .eventDetails(
                            eventVM,
                            detail.makeEventActionHandler(),
                            detail.upcomingOccurrences,
                            detail.detailDisplayOptions,
                            onSelectUpcomingOccurrence: detail.onSelectUpcomingOccurrence
                        )
                    )
                )
            } else {
                loadingPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Загрузка мероприятия…")
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
    }
}
