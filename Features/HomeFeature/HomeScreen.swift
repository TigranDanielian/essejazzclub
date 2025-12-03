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
    private var actionHandler: (EventAction) -> Void
    
    public init(
        viewModel: HomeScreenViewModel,
        uiFactory: any UIFactory,
        actionHandler: @escaping (EventAction) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // MARK: - Top events  block
                    ZStack {
                        TopLeftCutoutShape(
                            cutoutSize: .init(width: 165, height: 35),
                            cornerRadius: 12
                        )
                        .fill(Color(uiColor: Colors.altBackground), style: FillStyle(eoFill: true))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading) {
                            Text("Month events")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(Color(uiColor: Colors.text))
                                .padding(.horizontal, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .center, spacing: 8) {
                                    ForEach(viewModel.mainEvents) { event in
                                        AnyView(uiFactory.produce(unit: .event(event)))
                                            .frame(width: UIScreen.screenWidth * 0.9, height: 100)
                                            .onTapGesture {
                                                actionHandler(.onSelect(event))
                                            }
                                    }
                                }
                                .padding(12)
                                .frame(maxHeight: 200)
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    // MARK: - Today events block
                    
                    ZStack {
                        TopLeftCutoutShape(
                            cutoutSize: .init(width: 90, height: 35),
                            cornerRadius: 12
                        )
                        .fill(Color(uiColor: Colors.altBackground), style: FillStyle(eoFill: true))
                        .cornerRadius(12)
                        
                        DayView(title: "Today", sections: viewModel.todayEvents) { viewModel in
                            
                            uiFactory.produce(unit: .event(viewModel))
                                .onTapGesture {
                                    actionHandler(.onSelect(viewModel))
                                }
                        }
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 12)
                    
                    
                    // MARK: - Favorites block
                    
                    if !viewModel.favoriteEvents.isEmpty {
                        ZStack {
                            TopLeftCutoutShape(
                                cutoutSize: .init(width: 120, height: 35),
                                cornerRadius: 12
                            )
                            .fill(Color(uiColor: Colors.altBackground), style: FillStyle(eoFill: true))
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading) {
                                Text("Favorites")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(Color(uiColor: Colors.text))
                                    .padding(.horizontal, 12)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .center, spacing: 8) {
                                        ForEach(viewModel.favoriteEvents) { event in
                                            AnyView(uiFactory.produce(unit: .event(event)))
                                                .frame(width: UIScreen.screenWidth * 0.9, height: 100)
                                                .onTapGesture {
                                                    actionHandler(.onSelect(event))
                                                }
                                        }
                                    }
                                    .padding(12)
                                    .frame(maxHeight: 200)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .background(Color(uiColor: Colors.mainBackground))
        }
    }
}



//#Preview {
//    HomeScreen()
//}
