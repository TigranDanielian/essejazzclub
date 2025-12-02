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
                    
                    // MARK: - Today events block
                    
                    DayView(title: "Today", sections: viewModel.todayEvents) { viewModel in
                        
                        uiFactory.produce(unit: .event(viewModel))
                            .onTapGesture {
                                actionHandler(.onSelect(viewModel))
                            }
                    }
                    .padding(.horizontal, 6)
                    
                    
                    // MARK: - Favorites block
                    
                    if !viewModel.favoriteEvents.isEmpty {
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
                    
                    Spacer()
                }
            }
            .background(Color(uiColor: Colors.mainBackground))
        }
    }
}

@MainActor
public final class HomeScreenViewModel: ObservableObject {
    @Published var mainEvents: [EventViewModel] = []
    @Published var todayEvents: [GroupedEventSection] = []
    @Published var favoriteEvents: [EventViewModel] = []
    
    private var cancellables: Set<AnyCancellable> = []
    
    public init(
        eventsService: EventsService,
        viewModelFactory: ViewModelFactory,
        favoritesStorage: FavoritesStorage<String>
    ) {
        eventsService.state
            .tryMap { state in
                let viewModels = state.events.map { model -> EventViewModel in
                    viewModelFactory.produce(unit: .event(hasDate: true, model)) as! EventViewModel
                }
                
                let todayViewModels = viewModels.filter {
                    Calendar.current.date($0.date, matchesComponents: .init(day: 1))
                }
                
                let todaySections = [
                    GroupedEventSection(type: .mainStage, events: todayViewModels.filter({ !$0.isJazzLab })),
                    GroupedEventSection(type: .jazzLab, events: todayViewModels.filter({ $0.isJazzLab }))
                ]
                
                return (viewModels.filter({ $0.isTop }), todaySections)
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                let (mainEvents, todaySections) = $0
                self?.mainEvents = Array(mainEvents)
                self?.todayEvents = todaySections
            })
            .store(in: &cancellables)
        
        favoritesStorage.allFavorites(forKey: .events)
            .combineLatest(eventsService.state)
            .map { favIds, state in
                state.events.filter { favIds.contains($0.id) }.map {
                    viewModelFactory.produce(unit: .event(hasContextMenu: false, hasDate: true, $0)) as! EventViewModel
                }
            }
            .sink(receiveValue: { [weak self] in
                self?.favoriteEvents = $0
            })
            .store(in: &cancellables)
    }
}

//#Preview {
//    HomeScreen()
//}
