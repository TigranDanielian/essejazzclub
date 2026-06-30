//
//  HomeScreen.swift
//  API
//
//  Created by Tigran Danielian on 30.05.2025.
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

public struct HomeScreen: View {
    /// Родитель (`HomeTabShell`) держит VM в `@StateObject` — здесь только наблюдение.
    @ObservedObject public var viewModel: HomeScreenViewModel
    private let uiFactory: any UIFactory

    public init(
        viewModel: HomeScreenViewModel,
        uiFactory: any UIFactory
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
    }

    public var body: some View {
        Group {
            if viewModel.hasHeroBanner {
                HomeTopClampedScrollView(
                    showsIndicators: false,
                    scrollClipDisabled: true,
                    bounces: true,
                    onRefresh: { await viewModel.refresh() }
                ) {
                    homeSheetContent
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    homeSheetBody
                }
                .scrollBounceBehavior(.automatic, axes: .vertical)
                .appScrollContentBackgroundHidden()
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var homeSheetContent: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: HomeHeroSheetLayout.scrollHitExtensionHeight)
                .allowsHitTesting(false)

            homeSheetBody
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var homeSheetBody: some View {
        VStack(alignment: .leading, spacing: 32) {
            HomeUpcomingConcertsCarousel(
                sections: viewModel.upcomingEventSections,
                uiFactory: uiFactory,
                onEventDetails: { viewModel.onEventDetails($0) }
            )
            
            if !viewModel.favoriteConcertRows.isEmpty || !viewModel.favoriteMusicianRows.isEmpty {
                HomeScreenSection(title: "Избранное") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !viewModel.favoriteConcertRows.isEmpty {
                            homeFavoritesSubheader("Концерты")
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .center, spacing: 12) {
                                    ForEach(viewModel.favoriteConcertRows) { row in
                                        AnyView(uiFactory.produce(unit: .favoriteConcertRow(row)))
                                            .frame(width: homeFavoritesCarouselCardWidth(itemCount: viewModel.favoriteConcertRows.count))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                viewModel.onFavoriteConcertTap(row)
                                            }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        if !viewModel.favoriteMusicianRows.isEmpty {
                            homeFavoritesSubheader("Музыканты")
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .center, spacing: 12) {
                                    ForEach(viewModel.favoriteMusicianRows) { row in
                                        AnyView(uiFactory.produce(unit: .favoriteMusicianRow(row)))
                                            .frame(width: homeFavoritesCarouselCardWidth(itemCount: viewModel.favoriteMusicianRows.count))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                viewModel.onFavoriteMusicianTap(row)
                                            }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: Colors.mainBackground))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: viewModel.hasHeroBanner ? HomeHeroSheetLayout.sheetCornerRadius : 0,
                topTrailingRadius: viewModel.hasHeroBanner ? HomeHeroSheetLayout.sheetCornerRadius : 0
            )
        )
    }


    private func homeFavoritesSubheader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color(uiColor: Colors.accentSheet))
            .textCase(.uppercase)
            .padding(.horizontal, 16)
    }

    private func homeFavoritesCarouselCardWidth(itemCount: Int) -> CGFloat {
        if itemCount == 1 {
            return UIScreen.screenWidth - 32
        }
        return min(UIScreen.screenWidth * 0.88, 360)
    }
}

struct HomeScreenSection: View {
    var title: String
    var content: () -> any View
    @State private var textWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            TopLeftCutoutShape(
                cutoutSize: CGSize(width: textWidth, height: 40),
                cornerRadius: 12
            )
            .fill(DayBlockBackground.gradient, style: FillStyle(eoFill: true))
            .cornerRadius(12)

            Text(title)
                .font(.title)
                .bold()
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .padding(.horizontal, 12)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: TextWidthPreferenceKey.self,
                            value: geo.size.width
                        )
                    }
                )
                .onPreferenceChange(TextWidthPreferenceKey.self) { value in
                    textWidth = value
                }

            AnyView(content())
                .padding(.top, 60)
                .padding(.bottom, 12)
        }
        .cornerRadius(12)
    }
}
