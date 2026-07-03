//
//  MusicianViewModel.swift
//  SharedInfrastructure
//

import Foundation
import SwiftUI
import Combine
import Services
import Core

@MainActor
public final class MusicianViewModel: ObservableObject {
    /// Стабильный id для навигации (`Route.id`) и `Hashable` вне MainActor.
    public nonisolated let musicianId: Int

    public var name: String { presentation.name }
    public var description: String { presentation.description }
    public var text: String { presentation.text }
    public var profession: String { presentation.profession }

    @Published public var image: UIImage? = nil
    @Published public var isLoadingImage: Bool = false

    @Published public private(set) var upcomingEvents: [EventViewModel] = []
    @Published public private(set) var isLoadingUpcomingEvents = false

    /// Идентификатор для `FavoritesStorageKey.musicians` (совпадает с `id`).
    public var favoriteStorageId: String { id }

    public lazy var favoriteHeartButtonViewModel: FavoriteHeartButtonViewModel = FavoriteHeartButtonViewModel(
        favoritesStorage: favoritesStorage,
        value: favoriteStorageId,
        key: .musicians
    )

    public var imageLoadTask: Task<Void, Never>?
    private var upcomingEventsLoadTask: Task<Void, Never>?

    private var model: Musician
    private var presentation: MusicianPresentation { MusicianPresentation(model: model) }
    private let imageLoader: AsyncImageLoader
    private let favoritesStorage: FavoritesStorage<String>
    private let upcomingEventsProvider: MusicianUpcomingEventsProvider?

    public init(
        model: Musician,
        imageLoader: @escaping AsyncImageLoader,
        favoritesStorage: FavoritesStorage<String>,
        upcomingEventsProvider: MusicianUpcomingEventsProvider? = nil
    ) {
        self.musicianId = model.id
        self.model = model
        self.imageLoader = imageLoader
        self.favoritesStorage = favoritesStorage
        self.upcomingEventsProvider = upcomingEventsProvider
    }

    public func loadUpcomingEventsIfNeeded() {
        guard let upcomingEventsProvider else { return }
        guard upcomingEventsLoadTask == nil, upcomingEvents.isEmpty else { return }

        isLoadingUpcomingEvents = true
        upcomingEventsLoadTask = Task {
            defer {
                isLoadingUpcomingEvents = false
                upcomingEventsLoadTask = nil
            }

            let events = await loadUpcomingEvents(using: upcomingEventsProvider)
            guard !Task.isCancelled else { return }
            upcomingEvents = events
        }
    }

    public func cancelUpcomingEventsLoad() {
        upcomingEventsLoadTask?.cancel()
        upcomingEventsLoadTask = nil
        isLoadingUpcomingEvents = false
    }

    private func loadUpcomingEvents(using provider: MusicianUpcomingEventsProvider) async -> [EventViewModel] {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = provider(musicianId)
                .sink { events in
                    continuation.resume(returning: events)
                    cancellable?.cancel()
                }
        }
    }

    /// Обновляет данные музыканта при повторном `produce` из фабрики с актуальной моделью API.
    func replaceModel(_ model: Musician) {
        guard model.id == musicianId else { return }
        self.model = model
    }
}

// MARK: - RemoteImageLoadable

extension MusicianViewModel: RemoteImageLoadable {
    public var asyncImageLoader: AsyncImageLoader { imageLoader }
    public var remoteImageURL: String? { presentation.imageUrlString }
    public var remoteImageFailurePlaceholder: UIImage? { UIImage(systemName: "person.crop.circle") }
}

// MARK: - Identifiable

extension MusicianViewModel: Identifiable {
    public nonisolated var id: String { "\(musicianId)" }
}

// MARK: - Hashable

extension MusicianViewModel: Hashable {
    public nonisolated static func == (lhs: MusicianViewModel, rhs: MusicianViewModel) -> Bool {
        lhs.musicianId == rhs.musicianId
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(musicianId)
    }
}
