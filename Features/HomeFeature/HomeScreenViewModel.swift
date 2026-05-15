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

    @Published var mainEvents: [EventViewModel] = []
    @Published var todayEvents: [GroupedEventSection] = []
    @Published var favoriteConcertRows: [FavoriteConcertRow] = []
    @Published var favoriteMusicianRows: [FavoriteMusicianRow] = []

    private var cancellables: Set<AnyCancellable> = []
    private var musiciansCatalog: [Musician] = []
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
        self.viewModelFactory = viewModelFactory
        self.tabNavigation = tabNavigation
        self.contextHandler = contextHandler
        eventsService.state
            .tryMap { state in
                let viewModels = state.events.map { model -> EventViewModel in
                    viewModelFactory.produce(
                        unit: .event(hasContextMenu: false, hasDate: true, model)
                    ) as! EventViewModel
                }

                let todayViewModels = viewModels.filter {
                    Calendar.current.date($0.date, matchesComponents: .init(day: 9))
                }

                let todaySections = [
                    GroupedEventSection(type: .mainStage, events: todayViewModels.filter({ !$0.isJazzLab })),
                    GroupedEventSection(type: .jazzLab, events: todayViewModels.filter({ $0.isJazzLab }))
                ]

                return (viewModels.filter({ $0.isTop }), todaySections)
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                let (mainEvents, todaySections) = $0
                self?.mainEvents = Array(mainEvents)
                self?.todayEvents = todaySections
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

    func onEventDetails(_ viewModel: EventViewModel) {
        handleAction(.event(.navigation(.onEventDetails(viewModel))))
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
        guard let vm = viewModelFactory.produce(unit: .musician(musician)) as? MusicianViewModel else { return }
        tabNavigation.presentMusicianDetail(viewModel: vm)
    }
}
