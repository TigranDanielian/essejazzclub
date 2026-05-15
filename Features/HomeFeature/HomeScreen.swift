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
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Top events  block
                if !viewModel.mainEvents.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Главные события")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(Color(uiColor: Colors.text))
                            .padding(.horizontal, 12)
                        
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
                    
                    SeparatorView()
                }
                
                // MARK: - Today events block
                DayView(title: "Сегодня", sections: viewModel.todayEvents) { event in
                    uiFactory.produce(unit: .event(event))
                        .onTapGesture {
                            viewModel.onEventDetails(event)
                        }
                }
                .padding(.horizontal, 6)
                
                // MARK: - Favorites block (до 3 концертов и 3 музыкантов — горизонтальные слайдеры)
                
                if !viewModel.favoriteConcertRows.isEmpty || !viewModel.favoriteMusicianRows.isEmpty {
                    SeparatorView()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Избранное")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(Color(uiColor: Colors.text))
                            .padding(.horizontal, 16)
                        
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
                                .padding(.horizontal, 16)
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
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .background(Color(uiColor: Colors.mainBackground))
    }

    private func homeFavoritesSubheader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color(uiColor: Colors.secondaryText))
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

struct SeparatorView: View {
    var body: some View {
        Rectangle()
            .frame(height: 5)
            .cornerRadius(5)
            .foregroundColor(Color(uiColor: UIColor.darkGray))
            .padding(.horizontal, 20)
    }
}

//#Preview {
//    HomeScreen()
//}
