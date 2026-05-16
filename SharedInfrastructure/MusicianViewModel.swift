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
public final class MusicianViewModel: ObservableObject, Identifiable, Hashable {
    /// Стабильный id для навигации (`Route.id`) и `Hashable` вне MainActor.
    public nonisolated let musicianId: Int
    public nonisolated var id: String { "\(musicianId)" }

    public nonisolated static func == (lhs: MusicianViewModel, rhs: MusicianViewModel) -> Bool {
        lhs.musicianId == rhs.musicianId
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(musicianId)
    }
    public var name: String { model.name }
    public var description: String { model.description }
    public var text: String { model.text }
    public var profession: String { model.profession }
    
    @Published public var image: UIImage? = nil
    @Published public var isLoadingImage: Bool = false

    /// Идентификатор для `FavoritesStorageKey.musicians` (совпадает с `id`).
    public var favoriteStorageId: String { id }

    public lazy var favoriteButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(
        imagePublisher: favoriteHeartImagePublisher()
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

    private func favoriteHeartImagePublisher() -> AnyPublisher<UIImage?, Never> {
        favoritesStorage
            .isFavoritePublisher(for: favoriteStorageId, key: .musicians)
            .map { isFavorite in
                UIImage(systemName: isFavorite ? "heart.fill" : "heart")
            }
            .eraseToAnyPublisher()
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
