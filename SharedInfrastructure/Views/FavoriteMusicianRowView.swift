//
//  FavoriteMusicianRowView.swift
//  SharedInfrastructure
//

import SwiftUI
import Services
import Core

/// Плашка избранного музыканта: аватар, имя, подзаголовок.
public struct FavoriteMusicianRowView: View {
    let row: FavoriteMusicianRow
    let imageLoader: ImageLoader

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    public init(row: FavoriteMusicianRow, imageLoader: ImageLoader) {
        self.row = row
        self.imageLoader = imageLoader
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .background(
                    Circle()
                        .fill(Color(uiColor: Colors.cardBackground))
                )

                if isLoadingImage {
                    Circle()
                        .fill(Color(uiColor: Colors.secondaryText).opacity(0.15))
                        .frame(width: 72, height: 72)
                }
            }
            .frame(width: 72, height: 72)
            .eventHeroTransitionSource(
                sourceID: MusicianHeroTransitionSourceID.card(musicianId: row.musicianId)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(row.name)
                    .font(.headline)
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .multilineTextAlignment(.leading)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "music.mic")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    Text(row.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .task(id: row.id) {
            await loadAvatar()
        }
    }

    private func loadAvatar() async {
        guard let path = row.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else {
            return
        }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let loaded = try? await imageLoader.loadImage(path: path) {
            image = loaded
        }
    }
}
