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
    public struct ConcertDateChip: Identifiable, Hashable {
        public let id: String
        public let label: String

        public init(occurrenceIdentifier: String, label: String) {
            self.id = occurrenceIdentifier
            self.label = label
        }
    }

    public struct ConcertRow: Identifiable, Hashable {
        public let id: String
        public let eventId: String
        public let title: String
        public let thumbnailUrl: String?
        public let primaryOccurrenceIdentifier: String
        /// Ближайшие даты, `dd.MM`, для отображения чипами как время на деталке события.
        public let dateChips: [ConcertDateChip]
        public let sortDate: Date
    }

    public struct MusicianRow: Identifiable, Hashable {
        public let id: String
        public let musicianId: Int
        public let name: String
        public let subtitle: String
        public let imageUrl: String?
    }

    public let dependencies: ClubScreenDependencies
    public var router: ClubNavigationRouter

    @Published private(set) public var concertRows: [ConcertRow] = []
    @Published private(set) public var musicianRows: [MusicianRow] = []
    /// Каталог музыкантов с сервера для полной деталки.
    private(set) public var musiciansCatalog: [Musician] = []

    private var cancellables = Set<AnyCancellable>()

    public init(dependencies: ClubScreenDependencies) {
        self.dependencies = dependencies
        self.router = ClubNavigationRouter()
        router.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        bindFavorites()
    }

    public func musicianFromCatalog(id: Int) -> Musician? {
        musiciansCatalog.first { $0.id == id }
    }

    public func openHubRoute(_ route: ClubNavigationRouter.Route) {
        router.present(route: route, presentation: .push)
    }

    public func presentRoute(_ route: ClubNavigationRouter.Route, presentation: NavigationPresentationStyle = .push) {
        router.present(route: route, presentation: presentation)
    }

    public func popNavigation() {
        router.pop()
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
            let rows: [ConcertRow] = favoriteIds.compactMap { eventId in
                let occ = ClubFavoriteEventSchedule.occurrencesSorted(forEventId: eventId, in: state.events)
                guard let primary = ClubFavoriteEventSchedule.upcomingSubset(from: occ).first ?? occ.first else {
                    return nil
                }
                let chips = ClubFavoriteEventSchedule.upcomingDateChips(for: occ).map {
                    ConcertDateChip(occurrenceIdentifier: $0.occurrenceId, label: $0.label)
                }
                return ConcertRow(
                    id: eventId,
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
                    return MusicianRow(
                        id: idString,
                        musicianId: mid,
                        name: m.name,
                        subtitle: m.profession,
                        imageUrl: m.imageUrl
                    )
                }
                return MusicianRow(
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
