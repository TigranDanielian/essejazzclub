//
//  MusicianViewModel.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 04.12.2025.
//

import Foundation
import SwiftUI
import Services

public final class MusicianViewModel: ObservableObject, Identifiable {
    public var id: String { "\(model.id)" }
    public var name: String { model.name }
    public var description: String { model.description }
    public var profession: String { model.profession }
    
    @Published public var image: UIImage? = nil
    @Published public var isLoadingImage: Bool = false
    
    private let imageLoader: AsyncImageLoader
    private let model: Musician
    
    public init(model: Musician, imageLoader: @escaping AsyncImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
        
        Task { await loadImage() }
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
