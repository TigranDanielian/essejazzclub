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
import Services

public struct HomeScreen: View {
    @StateObject public var viewModel: HomeScreenViewModel
    @EnvironmentObject private var favoritesStorage: FavoritesStorage<String>
    private let uiFactory: any UIFactory
    private var actionHandler: (HomeScreenAction) -> Void
    
    public init(
        viewModel: HomeScreenViewModel,
        uiFactory: any UIFactory,
        actionHandler: @escaping (HomeScreenAction) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
        self.actionHandler = actionHandler
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
                                                actionHandler(.event(.navigation(.onEventDetails(event))))
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
                    DayView(title: "Сегодня", sections: viewModel.todayEvents) { viewModel in
                        
                        uiFactory.produce(unit: .event(viewModel))
                            .onTapGesture {
                                actionHandler(.event(.navigation(.onEventDetails(viewModel))))
                            }
                    }
                    .padding(.horizontal, 6)
                    
                    // MARK: - Favorites block
                    
                    if !viewModel.favoriteEvents.isEmpty {
                        SeparatorView()
                        
                        VStack(alignment: .leading) {
                            Text("Избранное")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(Color(uiColor: Colors.text))
                                .padding(.horizontal, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .center, spacing: 8) {
                                    ForEach(viewModel.favoriteEvents) { event in
                                        AnyView(uiFactory.produce(unit: .event(event)))
                                            .frame(
                                                width: viewModel.favoriteEvents.count == 1 
                                                    ? UIScreen.screenWidth - 24 
                                                    : UIScreen.screenWidth * 0.9,
                                                height: 100
                                            )
                                            .onTapGesture {
                                                actionHandler(.event(.navigation(.onEventDetails(event))))
                                            }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .frame(maxHeight: 200)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .background(Color(uiColor: Colors.mainBackground))
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
