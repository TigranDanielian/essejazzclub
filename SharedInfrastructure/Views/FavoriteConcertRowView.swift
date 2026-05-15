//
//  FavoriteConcertRowView.swift
//  SharedInfrastructure
//

import SwiftUI
import Services
import Core

/// Плашка избранного концерта: превью, название, чипы ближайших дат.
public struct FavoriteConcertRowView: View {
    let row: FavoriteConcertRow
    let imageLoader: ImageLoader

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    public init(row: FavoriteConcertRow, imageLoader: ImageLoader) {
        self.row = row
        self.imageLoader = imageLoader
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipped()
                    .background(Color(uiColor: Colors.cardBackground))
                    .cornerRadius(10)

                if isLoadingImage {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: Colors.secondaryText).opacity(0.15))
                        .frame(width: 88, height: 88)
                }
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.title)
                    .font(.headline)
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .multilineTextAlignment(.leading)

                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    if row.dateChips.isEmpty {
                        Text("Нет дат в афише")
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(row.dateChips) { chip in
                                    Text(chip.label)
                                        .padding(2)
                                        .font(.caption)
                                        .foregroundStyle(Color(uiColor: Colors.text))
                                        .background(Color(uiColor: Colors.mainBackground))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .task(id: row.id) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let path = row.thumbnailUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else {
            return
        }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let loaded = try? await imageLoader.loadImage(path: path) {
            image = loaded
        }
    }
}
