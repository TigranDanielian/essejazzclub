//
//  HomeScreen.swift
//  API
//
//  Created by Tigran Danielian on 30.05.2025.
//

import SwiftUI
import Combine
import Core
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
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 32) {
                // MARK: - Top events  block
                if !viewModel.mainEvents.isEmpty {
                    HomeScreenSection(title: "Главные события") {
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .center, spacing: 8) {
                                    ForEach(viewModel.mainEvents) { event in
                                        AnyView(uiFactory.produce(unit: .event(event)))
                                            .frame(
                                                width: viewModel.mainEvents.count == 1
                                                ? UIScreen.screenWidth - 24
                                                : UIScreen.screenWidth * 0.9,
                                                height: 100
                                            )
                                            .onTapGesture {
                                                viewModel.onEventDetails(event)
                                            }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .frame(maxHeight: 200)
                            }
                        }
                    }
                }
                
                // MARK: - Today events block
                HomeScreenSection(title: "Сегодня") {
                    DayView(sections: viewModel.todayEvents) { event in
                        uiFactory.produce(unit: .event(event))
                            .onTapGesture {
                                viewModel.onEventDetails(event)
                            }
                    }
                }
               
                
                // MARK: - Favorites block (до 3 концертов и 3 музыкантов — горизонтальные слайдеры)
                
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
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    viewModel.onFavoriteConcertTap(row)
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                            
                            if !viewModel.favoriteMusicianRows.isEmpty {
                                homeFavoritesSubheader("Музыканты")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .center, spacing: 12) {
                                        ForEach(viewModel.favoriteMusicianRows) { row in
                                            AnyView(uiFactory.produce(unit: .favoriteMusicianRow(row)))
                                                .frame(width: homeFavoritesCarouselCardWidth(itemCount: viewModel.favoriteMusicianRows.count))
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    viewModel.onFavoriteMusicianTap(row)
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .appScrollContentBackgroundHidden()
        .background(Color(uiColor: Colors.mainBackground))
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
                cutoutSize: CGSize(width: textWidth, height: 48),
                cornerRadius: 12
            )
            .fill(Color(uiColor: Colors.altBackground), style: FillStyle(eoFill: true))
            .cornerRadius(12)
            
            Text(title)
                .font(.largeTitle)
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

//#Preview {
//    HomeScreen()
//}
