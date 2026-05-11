//
//  ClubFavoritesViewModel.swift
//  ClubFeature
//

import Foundation
import Combine
import Core
import Services
import SharedInfrastructure

@MainActor
final class ClubFavoritesViewModel: ObservableObject {
    struct ConcertRow: Identifiable, Hashable {
        let id: String
        let eventId: String
        let title: String
        let thumbnailUrl: String?
        let primaryOccurrenceIdentifier: String
        let subtitle: String
        let sortDate: Date
    }

    struct MusicianRow: Identifiable, Hashable {
        let id: String
        let musicianId: Int
        let name: String
        let subtitle: String
        let imageUrl: String?
    }

    @Published private(set) var concertRows: [ConcertRow] = []
    @Published private(set) var musicianRows: [MusicianRow] = []
    /// Актуальный список музыкантов с сервера — для открытия деталки с полным текстом.
    private(set) var musiciansCatalog: [Musician] = []

    private var cancellables = Set<AnyCancellable>()

    func musicianFromCatalog(id: Int) -> Musician? {
        musiciansCatalog.first { $0.id == id }
    }

    init(eventsService: EventsService, musiciansService: MusiciansService, favoritesStorage: FavoritesStorage<String>) {
        Publishers.CombineLatest(
            favoritesStorage.allFavorites(forKey: .events),
            eventsService.state
        )
        .receive(on: DispatchQueue.main)
        .map { favoriteIds, state -> [ConcertRow] in
            let rows: [ConcertRow] = favoriteIds.compactMap { eventId in
                let occ = ClubFavoriteEventSchedule.occurrencesSorted(forEventId: eventId, in: state.events)
                guard let primary = ClubFavoriteEventSchedule.upcomingSubset(from: occ).first ?? occ.first else {
                    return nil
                }
                let subtitle = ClubFavoriteEventSchedule.listSubtitle(for: occ)
                return ConcertRow(
                    id: eventId,
                    eventId: eventId,
                    title: primary.title,
                    thumbnailUrl: primary.thumbnailUrl,
                    primaryOccurrenceIdentifier: eventOccurrenceIdentifier(for: primary),
                    subtitle: subtitle,
                    sortDate: primary.dateWithTimes.date
                )
            }
            return rows.sorted { $0.sortDate < $1.sortDate }
        }
        .sink { [weak self] in self?.concertRows = $0 }
        .store(in: &cancellables)

        Publishers.CombineLatest(
            favoritesStorage.allFavorites(forKey: .musicians),
            musiciansService.state
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
