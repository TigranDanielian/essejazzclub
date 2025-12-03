//
//  HomeScreenViewModel.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 02.12.2025.
//

import Foundation
import Combine
import Services
import Core
import SharedInfrastructure

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
