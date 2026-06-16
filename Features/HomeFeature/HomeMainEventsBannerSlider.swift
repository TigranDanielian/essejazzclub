//
//  HomeMainEventsBannerSlider.swift
//  HomeFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

enum HomeMainEventBannerLayout {
    static let textBlockHeight: CGFloat = 112
    static let cornerRadius: CGFloat = 14
    static let horizontalInset: CGFloat = 12
    static let pageIndicatorInset: CGFloat = 32

    static var cardWidth: CGFloat {
        UIScreen.screenWidth - horizontalInset * 2
    }

    static var imageHeight: CGFloat { cardWidth }

    static var cardHeight: CGFloat {
        imageHeight + textBlockHeight
    }

    static var sliderHeight: CGFloat {
        cardHeight + pageIndicatorInset
    }
}

struct HomeMainEventsBannerSlider: View {
    let events: [EventViewModel]
    let imageLoader: ImageLoader
    let onSelect: (EventViewModel) -> Void

    var body: some View {
        TabView {
            ForEach(events) { event in
                VStack(spacing: 0) {
                    HomeMainEventBannerPage(
                        event: event,
                        imageLoader: imageLoader,
                        onTap: { onSelect(event) }
                    )
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, HomeMainEventBannerLayout.horizontalInset)
            }
        }
        .frame(height: HomeMainEventBannerLayout.sliderHeight)
        .tabViewStyle(.page(indexDisplayMode: events.count > 1 ? .automatic : .never))
    }
}

private struct HomeMainEventBannerPage: View {
    let event: EventViewModel
    let imageLoader: ImageLoader
    let onTap: () -> Void

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                imageSection
                textSection
            }
            .frame(
                width: HomeMainEventBannerLayout.cardWidth,
                height: HomeMainEventBannerLayout.cardHeight,
                alignment: .top
            )
            .fixedSize(horizontal: true, vertical: true)
            .clipShape(RoundedRectangle(cornerRadius: HomeMainEventBannerLayout.cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: HomeMainEventBannerLayout.cornerRadius))
        }
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(HomeMainEventBannerLayout.cornerRadius)
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .task(id: event.occurrenceIdentifier) {
            image = nil
            await loadPosterIfNeeded()
        }
    }

    private var imageSection: some View {
        ZStack(alignment: .top) {
            Color(uiColor: Colors.mainBackground)

            if let image {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                }
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isLoadingImage {
                SkeletonView()
            }
        }
        .frame(
            width: HomeMainEventBannerLayout.cardWidth,
            height: HomeMainEventBannerLayout.imageHeight
        )
        .cornerRadius(HomeMainEventBannerLayout.cornerRadius)
        .clipped()
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                dateAndTimeRow
                    .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .leading)
                
                Text(event.priceString ?? " ")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(uiColor: Colors.primary))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20, alignment: .leading)
                    .opacity(event.priceString?.isEmpty == false ? 1 : 0)
            }
           
            Text(event.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(uiColor: Colors.text))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 52, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(
            width: HomeMainEventBannerLayout.cardWidth,
            height: HomeMainEventBannerLayout.textBlockHeight,
            alignment: .topLeading
        )
        .background(Color(uiColor: Colors.cardBackground))
        .clipped()
    }

    private var dateAndTimeRow: some View {
        HStack(spacing: 6) {
            Text(event.dateString(format: "d MMMM"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .lineLimit(1)

            if !event.times.isEmpty {
                ForEach(event.times, id: \.self) { time in
                    EventTimeView(time: time)
                }
            }
        }
        .lineLimit(1)
    }

    private func loadPosterIfNeeded() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }

        let path = event.imageUrlString ?? event.bannerUrlString
        let maxPixelSize = HomeMainEventBannerLayout.cardWidth * UIScreen.main.scale
        image = await PathImageLoading.load(
            imageLoader: imageLoader,
            path: path,
            maxPixelSize: maxPixelSize
        )
    }
}
