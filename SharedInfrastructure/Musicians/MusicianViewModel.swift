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

    /// Идентификатор для `FavoritesStorageKey.musicians` (совпадает с `id`).
    public var favoriteStorageId: String { id }

    public lazy var favoriteButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(
        imagePublisher: EventContextButtonPublishers.favoriteHeart(
            favoritesStorage: favoritesStorage,
            value: favoriteStorageId,
            key: .musicians
        )
    )

    public var imageLoadTask: Task<Void, Never>?

    private var model: Musician
    private var presentation: MusicianPresentation { MusicianPresentation(model: model) }
    private let imageLoader: AsyncImageLoader
    private let favoritesStorage: FavoritesStorage<String>

    public init(
        model: Musician,
        imageLoader: @escaping AsyncImageLoader,
        favoritesStorage: FavoritesStorage<String>
    ) {
        self.musicianId = model.id
        self.model = model
        self.imageLoader = imageLoader
        self.favoritesStorage = favoritesStorage
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
