//
//  ClubScreenViewModel.swift
//  ClubFeature
//

import Combine
import Foundation
import SwiftUI
import Core
import Services
import SharedInfrastructure

/// Вью-модель вкладки «Клуб»: зависимости, избранное, делегирование навигации роутеру.
@MainActor
public final class ClubScreenViewModel: ObservableObject {
    public typealias ConcertDateChip = FavoriteConcertDateChip
    public typealias ConcertRow = FavoriteConcertRow
    public typealias MusicianRow = FavoriteMusicianRow

    public let dependencies: ClubScreenDependencies
    public var router: ClubNavigationRouter

    public var tabNavigation: ClubTabNavigating { router }

    @Published private(set) public var concertRows: [ConcertRow] = []
    @Published private(set) public var musicianRows: [MusicianRow] = []
    /// Каталог музыкантов с сервера для полной деталки.
    private(set) public var musiciansCatalog: [Musician] = []

    private var cancellables = Set<AnyCancellable>()

    public init(dependencies: ClubScreenDependencies) {
        self.dependencies = dependencies
        self.router = ClubNavigationRouter()
        bindFavorites()
    }

    public func musicianFromCatalog(id: Int) -> Musician? {
        musiciansCatalog.first { $0.id == id }
    }

    public func openHubRoute(_ route: ClubNavigationRouter.Route) {
        tabNavigation.openHubRoute(route)
    }

    public func presentRoute(_ route: ClubNavigationRouter.Route, presentation: NavigationPresentationStyle = .push) {
        tabNavigation.presentClubRoute(route, presentation: presentation)
    }

    public func popNavigation() {
        tabNavigation.dismissPresentedOrPop()
    }

    private func bindFavorites() {
        let favorites = dependencies.favoritesStorage
        let events = dependencies.eventsService
        let musicians = dependencies.musiciansService

        Publishers.CombineLatest(
            favorites.allFavorites(forKey: .events),
            events.state
        )
        .receive(on: DispatchQueue.main)
        .map { favoriteIds, state -> [ConcertRow] in
            var seen = Set<String>()
            let rows: [ConcertRow] = favoriteIds.compactMap { eventId -> ConcertRow? in
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
            return rows.sorted { $0.sortDate < $1.sortDate }
        }
        .sink { [weak self] in self?.concertRows = $0 }
        .store(in: &cancellables)

        Publishers.CombineLatest(
            favorites.allFavorites(forKey: .musicians),
            musicians.state
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] favoriteIds, musicState in
            guard let self else { return }
            let catalog = musicState.musicians
            musiciansCatalog = catalog
            let rows: [MusicianRow] = favoriteIds.compactMap { idString in
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
            musicianRows = rows.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        .store(in: &cancellables)
    }
}
