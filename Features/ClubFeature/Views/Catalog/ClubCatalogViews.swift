//
//  ClubCatalogViews.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

enum ClubCatalogGridLayout {
    static let screenEdgeInset: CGFloat = 12
    static let columnSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 28
    static let cardHeight: CGFloat = 240
    static let infoBarHeight: CGFloat = 80

    static var cellWidth: CGFloat {
        let totalWidth = UIScreen.screenWidth
        return (totalWidth - screenEdgeInset * 2 - columnSpacing) / 2
    }

    static var imageSlotHeight: CGFloat { cardHeight - infoBarHeight }
}

struct ClubCatalogEmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ClubCatalogCategoryChip: View {
    let title: String
    let isSelected: Bool
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(
                    isSelected
                        ? Color(uiColor: Colors.textOnAccent)
                        : Color(uiColor: Colors.text)
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? Color(uiColor: Colors.accent)
                                : Color(uiColor: Colors.cardBackground)
                        )
                )
        }
        .buttonStyle(.plain)
        .id(id)
    }
}

enum ClubCatalogCategoryTabs {
    static func center(_ id: String, proxy: ScrollViewProxy) {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}

struct ClubCatalogGridCard: View {
    let title: String
    let subtitle: String?
    let imagePath: String?
    let placeholderSystemName: String
    let imageLoader: ImageLoader
    let cellWidth: CGFloat
    let loadTaskID: String

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    private var imageSlotSize: CGSize {
        CGSize(width: cellWidth, height: ClubCatalogGridLayout.imageSlotHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            photoSlot
                .frame(width: imageSlotSize.width, height: imageSlotSize.height)
                .clipped()

            infoBar
                .frame(width: cellWidth, height: ClubCatalogGridLayout.infoBarHeight)
        }
        .frame(width: cellWidth, height: ClubCatalogGridLayout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .task(id: loadTaskID) {
            image = nil
            await loadImageIfNeeded()
        }
    }

    @ViewBuilder
    private var photoSlot: some View {
        let width = imageSlotSize.width
        let height = imageSlotSize.height
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else if isLoadingImage {
                SkeletonView()
                    .frame(width: width, height: height)
            } else {
                ZStack {
                    Color(uiColor: Colors.cardBackground)
                    Image(systemName: placeholderSystemName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: width * 0.45, maxHeight: height * 0.45)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                }
                .frame(width: width, height: height)
            }
        }
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(uiColor: Colors.accentSheet))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(uiColor: Colors.cardBackground))
    }

    private func loadImageIfNeeded() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }
        image = await PathImageLoading.load(imageLoader: imageLoader, path: imagePath)
    }
}
