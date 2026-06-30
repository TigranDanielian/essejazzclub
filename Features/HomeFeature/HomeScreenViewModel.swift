//
//  HomeScreenViewModel.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 02.12.2025.
//

import Foundation
import Combine
import Services
import Core
import SharedInfrastructure

@MainActor
public final class HomeScreenViewModel: ObservableObject {
    /// Максимум элементов в каждом горизонтальном слайдере «Избранное» на главной.
    public static let homeFavoritesCarouselLimit = 3

    @Published public var mainEvents: [EventViewModel] = []
    @Published var upcomingEventSections: [GroupedEventSection] = []
    @Published var favoriteConcertRows: [FavoriteConcertRow] = []
    @Published var favoriteMusicianRows: [FavoriteMusicianRow] = []

    public var hasHeroBanner: Bool { !mainEvents.isEmpty }

    private var cancellables: Set<AnyCancellable> = []
    private var musiciansCatalog: [Musician] = []
    private let eventsService: EventsService
    private let musiciansService: MusiciansService
    private let viewModelFactory: ViewModelFactory
    private let tabNavigation: HomeTabNavigating
    private let contextHandler: (EventContextButtonType) -> Void

    public init(
        eventsService: EventsService,
        musiciansService: MusiciansService,
        viewModelFactory: ViewModelFactory,
        favoritesStorage: FavoritesStorage<String>,
        tabNavigation: HomeTabNavigating,
        contextHandler: @escaping (EventContextButtonType) -> Void
    ) {
        self.eventsService = eventsService
        self.musiciansService = musiciansService
        self.viewModelFactory = viewModelFactory
        self.tabNavigation = tabNavigation
        self.contextHandler = contextHandler
        eventsService.state
            .tryMap { state in
                let calendar = Calendar.current
                let todayStart = calendar.startOfDay(for: Date())
                let upcomingEnd = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart

                func isUpcoming(_ date: Date) -> Bool {
                    let day = calendar.startOfDay(for: date)
                    return day >= todayStart && day < upcomingEnd
                }

                let mainEvents: [EventViewModel] = state.events
                    .filter(\.isTop)
                    .map { model in
                        viewModelFactory.produce(
                            unit: .event(hasContextMenu: false, hasDate: false, model)
                        ) as! EventViewModel
                    }

                let upcomingModels = state.events
                    .filter { isUpcoming($0.dateWithTimes.date) }
                    .sorted { lhs, rhs in
                        if lhs.dateWithTimes.date != rhs.dateWithTimes.date {
                            return lhs.dateWithTimes.date < rhs.dateWithTimes.date
                        }
                        let lhsTime = lhs.dateWithTimes.times.map(\.time).min() ?? lhs.dateWithTimes.date
                        let rhsTime = rhs.dateWithTimes.times.map(\.time).min() ?? rhs.dateWithTimes.date
                        if lhsTime != rhsTime {
                            return lhsTime < rhsTime
                        }
                        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                    }

                let upcomingViewModels = upcomingModels.map { model in
                    viewModelFactory.produce(
                        unit: .event(hasContextMenu: false, hasDate: true, hasPrice: false, model)
                    ) as! EventViewModel
                }

                let mainStage = upcomingViewModels.filter { !$0.isJazzLab }
                let jazzLab = upcomingViewModels.filter { $0.isJazzLab }

                var upcomingEventSections: [GroupedEventSection] = []
                if !mainStage.isEmpty {
                    upcomingEventSections.append(GroupedEventSection(type: .mainStage, events: mainStage))
                }
                if !jazzLab.isEmpty {
                    upcomingEventSections.append(GroupedEventSection(type: .jazzLab, events: jazzLab))
                }

                return (mainEvents, upcomingEventSections)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                let (mainEvents, upcomingEventSections) = $0
                self?.mainEvents = mainEvents
                self?.upcomingEventSections = upcomingEventSections
            })
            .store(in: &cancellables)

        favoritesStorage.allFavorites(forKey: .events)
            .combineLatest(eventsService.state)
            .map { favIds, state -> [FavoriteConcertRow] in
                var seen = Set<String>()
                let rows: [FavoriteConcertRow] = favIds.compactMap { eventId -> FavoriteConcertRow? in
                    guard seen.insert(eventId).inserted else { return nil }
                    let occ = FavoriteEventSchedule.sortedOccurrences(forEventId: eventId, in: state.events)
                    guard let primary = FavoriteEventSchedule.primaryOccurrence(forEventId: eventId, in: state.events) else {
                        return nil
                    }
                    let chips = FavoriteEventSchedule.upcomingDateChips(fromOccurrences: occ).map {
                        FavoriteConcertDateChip(occurrenceIdentifier: $0.occurrenceId, label: $0.label)
                    }
                    return FavoriteConcertRow(
                        eventId: eventId,
                        title: primary.title,
                        thumbnailUrl: primary.thumbnailUrl,
                        primaryOccurrenceIdentifier: eventOccurrenceIdentifier(for: primary),
                        dateChips: chips,
                        sortDate: primary.dateWithTimes.date
                    )
                }
                let sorted = rows.sorted { $0.sortDate < $1.sortDate }
                return Array(sorted.prefix(Self.homeFavoritesCarouselLimit))
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.favoriteConcertRows = $0
            })
            .store(in: &cancellables)

        favoritesStorage.allFavorites(forKey: .musicians)
            .combineLatest(musiciansService.state)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favoriteIds, musicState in
                guard let self else { return }
                let catalog = musicState.musicians
                self.musiciansCatalog = catalog
                let rows: [FavoriteMusicianRow] = favoriteIds.compactMap { idString -> FavoriteMusicianRow? in
                    guard let mid = Int(idString) else { return nil }
                    if let m = catalog.first(where: { $0.id == mid }) {
                        return FavoriteMusicianRow(
                            id: idString,
                            musicianId: mid,
                            name: m.name,
                            subtitle: m.profession,
                            imageUrl: m.imageUrl
                        )
                    }
                    return FavoriteMusicianRow(
                        id: idString,
                        musicianId: mid,
                        name: "Музыкант",
                        subtitle: "Нет в загруженном списке",
                        imageUrl: nil
                    )
                }
                let sorted = rows.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.favoriteMusicianRows = Array(sorted.prefix(Self.homeFavoritesCarouselLimit))
            }
            .store(in: &cancellables)
    }
    
    public func refresh() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var cancellable: AnyCancellable?
            cancellable = Publishers.CombineLatest(
                eventsService.load(),
                musiciansService.load()
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    continuation.resume()
                    cancellable = nil
                },
                receiveValue: { _ in }
            )
        }
    }

    public func handleAction(_ action: HomeScreenAction) {
        switch action {
        case .event(let eventAction):
            applyEventActionParts(
                eventAction,
                applyNavigation: { tabNavigation.applyEventNavigation($0) },
                handleContextButton: contextHandler
            )
        case .musician(let musicianAction):
            tabNavigation.applyMusicianNavigation(musicianAction)
        }
    }

    public func onEventDetails(_ viewModel: EventViewModel) {
        onEventDetails(
            viewModel,
            heroTransitionSourceID: EventHeroTransitionSourceID.card(
                occurrenceIdentifier: viewModel.occurrenceIdentifier
            )
        )
    }

    public func onEventDetails(_ viewModel: EventViewModel, heroTransitionSourceID: String?) {
        handleAction(.event(.navigation(.onEventDetails(viewModel, heroTransitionSourceID: heroTransitionSourceID))))
    }

    public func onFavoriteConcertTap(_ row: FavoriteConcertRow) {
        tabNavigation.presentBookmarkedEventOverview(occurrenceIdentifier: row.primaryOccurrenceIdentifier)
    }

    public func onFavoriteMusicianTap(_ row: FavoriteMusicianRow) {
        let musician = musiciansCatalog.first(where: { $0.id == row.musicianId })
            ?? Musician(
                id: row.musicianId,
                name: row.name,
                description: "",
                text: "",
                profession: row.subtitle,
                imageUrl: row.imageUrl
            )
        guard let viewModel = viewModelFactory.produce(unit: .musician(musician)) as? MusicianViewModel else { return }
        tabNavigation.presentMusicianDetail(viewModel: viewModel)
    }
}
