//
//  HomeHeroOverlaySlider.swift
//  HomeFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

/// Герой-слайдер: превью, затемнение, название, время и «Подробнее» слева.
struct HomeHeroOverlaySlider: View {
    let events: [EventViewModel]
    let imageLoader: ImageLoader
    let onDetails: (EventViewModel) -> Void

    @State private var selectedIndex = 0

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(events.indices, id: \.self) { index in
                HomeHeroOverlaySlide(
                    event: events[index],
                    imageLoader: imageLoader,
                    onDetails: { onDetails(events[index]) }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            if events.count > 1 {
                HomeHeroPageIndicator(count: events.count, selection: selectedIndex)
                    .padding(.bottom, HomeHeroSheetLayout.pageIndicatorBottomInset + HomeHeroSheetLayout.pageIndicatorLift)
                    .padding(.horizontal, 16)
            }
        }
    }
}

private struct HomeHeroPageIndicator: View {
    let count: Int
    let selection: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< count, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index == selection ? 1 : 0.35))
                    .frame(height: 3)
                    .cornerRadius(2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selection)
    }
}

private struct HomeHeroOverlaySlide: View {
    let event: EventViewModel
    let imageLoader: ImageLoader
    let onDetails: () -> Void

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            posterBackground

            LinearGradient(
                colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.15)
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                Spacer()

                Text(event.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(uiColor: Colors.textInverted))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Text(event.dateString)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(uiColor: Colors.textInverted))
                        .multilineTextAlignment(.leading)

                    if !event.times.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(event.times, id: \.self) { time in
                                Text(time)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(uiColor: Colors.textInverted))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.18))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }

                Button(action: onDetails) {
                    Text("Подробнее")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(uiColor: Colors.textInverted))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, UIScreen.safeAreaTop + 12)
            .padding(.bottom, 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .top)
        .offset(y: -32)
        .task(id: event.occurrenceIdentifier) {
            image = nil
            await loadPosterIfNeeded()
        }
    }

    @ViewBuilder
    private var posterBackground: some View {
        ZStack {
            Color(uiColor: Colors.cardBackground)

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
                    .font(.system(size: 44))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isLoadingImage {
                SkeletonView()
            }
        }
    }

    private func loadPosterIfNeeded() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }

        guard let path = event.imageUrlString, !path.isEmpty else { return }

        let maxPixelSize = UIScreen.screenWidth * UIScreen.main.scale
        image = await PathImageLoading.load(
            imageLoader: imageLoader,
            path: path,
            maxPixelSize: maxPixelSize
        )
    }
}

/// Герой-баннер внутри root `NavigationStack` (не в pushed destination).
public struct HomeHeroBanner: View {
    let events: [EventViewModel]
    let imageLoader: ImageLoader
    let onDetails: (EventViewModel) -> Void

    public init(
        events: [EventViewModel],
        imageLoader: ImageLoader,
        onDetails: @escaping (EventViewModel) -> Void
    ) {
        self.events = events
        self.imageLoader = imageLoader
        self.onDetails = onDetails
    }

    public var body: some View {
        HomeHeroOverlaySlider(
            events: events,
            imageLoader: imageLoader,
            onDetails: onDetails
        )
        .frame(height: HomeHeroSheetLayout.sliderHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .ignoresSafeArea(edges: .top)
    }
}
