//
//  HomeHeroShell.swift
//  HomeFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

/// Каркас главного экрана: фон → баннер → scroll поверх.
public struct HomeHeroShell<ScrollContent: View>: View {
    let hasBanner: Bool
    let showsBanner: Bool
    let isBannerPlaybackActive: Bool
    let bannerEvents: [EventViewModel]
    let imageLoader: ImageLoader
    let onBannerEventDetails: (EventViewModel) -> Void
    @ViewBuilder let scrollContent: () -> ScrollContent

    public init(
        hasBanner: Bool,
        showsBanner: Bool,
        isBannerPlaybackActive: Bool,
        bannerEvents: [EventViewModel],
        imageLoader: ImageLoader,
        onBannerEventDetails: @escaping (EventViewModel) -> Void,
        @ViewBuilder scrollContent: @escaping () -> ScrollContent
    ) {
        self.hasBanner = hasBanner
        self.showsBanner = showsBanner
        self.isBannerPlaybackActive = isBannerPlaybackActive
        self.bannerEvents = bannerEvents
        self.imageLoader = imageLoader
        self.onBannerEventDetails = onBannerEventDetails
        self.scrollContent = scrollContent
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: Colors.mainBackground)
                .ignoresSafeArea()

            if hasBanner {
                HomeHeroBanner(
                    events: bannerEvents,
                    imageLoader: imageLoader,
                    isPlaybackActive: isBannerPlaybackActive,
                    onDetails: onBannerEventDetails
                )
                .frame(height: HomeHeroSheetLayout.bannerHeight)
                .opacity(showsBanner ? 1 : 0)
                .animation(nil, value: showsBanner)
                .allowsHitTesting(showsBanner)
                .accessibilityHidden(!showsBanner)
            }
            
            Color(uiColor: Colors.mainBackground)
                .cornerRadius(16)
                .padding(.top, HomeHeroSheetLayout.scrollPassthroughHeight)
                .ignoresSafeArea(edges: .top)

            scrollContent()
        }
        .ignoresSafeArea(edges: .top)
    }
}
