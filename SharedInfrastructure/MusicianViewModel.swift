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

public final class MusicianViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: MusicianViewModel, rhs: MusicianViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var id: String { "\(model.id)" }
    public var musicianId: Int { model.id }
    public var name: String { model.name }
    public var description: String { model.description }
    public var text: String { model.text }
    public var profession: String { model.profession }
    
    @Published public var image: UIImage? = nil
    @Published public var isLoadingImage: Bool = false

    /// Идентификатор для `FavoritesStorageKey.musicians` (совпадает с `id`).
    public var favoriteStorageId: String { id }

    @MainActor
    public lazy var favoriteButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(
        imagePublisher: favoriteHeartImagePublisher()
    )

    private let imageLoader: AsyncImageLoader
    private let favoritesStorage: FavoritesStorage<String>
    private let model: Musician

    public init(
        model: Musician,
        imageLoader: @escaping AsyncImageLoader,
        favoritesStorage: FavoritesStorage<String>
    ) {
        self.model = model
        self.imageLoader = imageLoader
        self.favoritesStorage = favoritesStorage

        Task { await loadImage() }
    }

    @MainActor
    private func favoriteHeartImagePublisher() -> AnyPublisher<UIImage?, Never> {
        favoritesStorage
            .isFavoritePublisher(for: favoriteStorageId, key: .musicians)
            .map { isFavorite in
                UIImage(systemName: isFavorite ? "heart.fill" : "heart")
            }
            .eraseToAnyPublisher()
    }
    
    @MainActor
    private func loadImage() async {
        if let imageUrlString = model.imageUrl {
            isLoadingImage = true
            do {
                let loadedImage = try await imageLoader(imageUrlString)
                self.image = loadedImage
                isLoadingImage = false
            }
            catch {
                self.image = UIImage(systemName: "person.crop.circle")
                isLoadingImage = false
            }
        }
    }
}
