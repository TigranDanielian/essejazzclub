//
//  MusicianViewModel.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 04.12.2025.
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

    public var name: String { model.name }
    public var description: String { model.description }
    public var text: String { model.text }
    public var profession: String { model.profession }

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

    private let imageLoader: AsyncImageLoader
    private let favoritesStorage: FavoritesStorage<String>
    private let model: Musician
    private var imageLoadTask: Task<Void, Never>?

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

    /// Запускает загрузку фото, если ещё нет картинки и нет активной задачи.
    public func loadImageIfNeeded() {
        guard image == nil, model.imageUrl != nil else { return }
        guard imageLoadTask == nil else { return }

        imageLoadTask = Task { [weak self] in
            await self?.loadImage()
        }
    }

    /// Отменяет незавершённую загрузку (например, ячейка ушла с экрана). Уже загруженное фото сохраняется.
    public func cancelImageLoad() {
        guard image == nil else { return }
        imageLoadTask?.cancel()
        imageLoadTask = nil
        isLoadingImage = false
    }

    private func loadImage() async {
        defer {
            imageLoadTask = nil
            if !Task.isCancelled {
                isLoadingImage = false
            }
        }

        guard !Task.isCancelled else { return }
        guard let imageUrlString = model.imageUrl else { return }

        isLoadingImage = true
        do {
            let loadedImage = try await imageLoader(imageUrlString)
            guard !Task.isCancelled else { return }
            self.image = loadedImage
        } catch {
            guard !Task.isCancelled else { return }
            self.image = UIImage(systemName: "person.crop.circle")
        }
    }
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
