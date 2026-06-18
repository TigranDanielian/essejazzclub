//
//  HomeFeaturedBannerSlider.swift
//  HomeFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

/// Широкий баннер на главной: только картинка, без текста; изображение целиком в прямоугольнике.
enum HomeFeaturedBannerLayout {
    /// Соотношение сторон баннера из API (ширина / высота).
    static let bannerAspectRatio: CGFloat = 2.4
    static let cornerRadius: CGFloat = 14
    static let horizontalInset: CGFloat = 12
    static let pageIndicatorInset: CGFloat = 24

    static var bannerWidth: CGFloat {
        UIScreen.screenWidth - horizontalInset * 2
    }

    static var bannerHeight: CGFloat {
        bannerWidth / bannerAspectRatio
    }

    static var sliderHeight: CGFloat {
        bannerHeight + pageIndicatorInset
    }
}

struct HomeFeaturedBannerSlider: View {
    let events: [EventViewModel]
    let imageLoader: ImageLoader
    let onSelect: (EventViewModel) -> Void

    var body: some View {
        TabView {
            ForEach(events) { event in
                VStack(spacing: 0) {
                    HomeFeaturedBannerPage(
                        event: event,
                        imageLoader: imageLoader,
                        onTap: { onSelect(event) }
                    )
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, HomeFeaturedBannerLayout.horizontalInset)
            }
        }
        .frame(height: HomeFeaturedBannerLayout.sliderHeight)
        .tabViewStyle(.page(indexDisplayMode: events.count > 1 ? .automatic : .never))
    }
}

private struct HomeFeaturedBannerPage: View {
    let event: EventViewModel
    let imageLoader: ImageLoader
    let onTap: () -> Void

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Color(uiColor: Colors.cardBackground)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: HomeFeaturedBannerLayout.bannerWidth,
                            height: HomeFeaturedBannerLayout.bannerHeight
                        )
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                }

                if isLoadingImage {
                    SkeletonView()
                }
            }
            .frame(
                width: HomeFeaturedBannerLayout.bannerWidth,
                height: HomeFeaturedBannerLayout.bannerHeight
            )
            .clipShape(RoundedRectangle(cornerRadius: HomeFeaturedBannerLayout.cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: HomeFeaturedBannerLayout.cornerRadius))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .task(id: event.occurrenceIdentifier) {
            image = nil
            await loadBannerIfNeeded()
        }
    }

    private func loadBannerIfNeeded() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }

        guard let path = event.bannerUrlString else { return }

        let maxPixelSize = HomeFeaturedBannerLayout.bannerWidth * UIScreen.main.scale
        image = await PathImageLoading.load(
            imageLoader: imageLoader,
            path: path,
            maxPixelSize: maxPixelSize
        )
    }
}
