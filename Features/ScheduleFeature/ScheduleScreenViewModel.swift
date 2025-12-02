//
//  ScheduleScreenViewModel.swift
//  ScheduleFeature
//
//  Created by Tigran Danielian on 30.05.2025.
//

import Foundation
import Services
import Combine
import SwiftUI
import Core
import SharedInfrastructure

@MainActor
public final class ScheduleScreenViewModel: ObservableObject {
    @Published var grouped: [GroupedEventsByDay] = []
    private var cancellables: Set<AnyCancellable> = []
    @Published var selectedEvent: EventViewModel?
    @Published var searchInputText: String = ""
    
    public init(
        eventsService: EventsService,
        viewModelFactory: ViewModelFactory
    ) {
        eventsService.state
            .combineLatest($searchInputText.removeDuplicates())
            .tryMap { state, searchInput in
                state.events.map { model -> EventViewModel in
                    viewModelFactory.produce(unit: .event(hasContextMenu: true, model)) as! EventViewModel
                }
                .filter { viewModel in
                    guard !searchInput.isEmpty else { return true }
                 
                    return viewModel.title.lowercased().contains(searchInput.lowercased())
                }
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                self?.groupEvents($0)
            })
            .store(in: &cancellables)
    }
    
    func groupEvents(_ viewModels: [EventViewModel]) {
        let groupedByDate = Dictionary(grouping: viewModels) { $0.date }
        
        self.grouped = groupedByDate.map { (date, events) in
            let main = events.filter { !$0.isJazzLab }
            let jazzLab = events.filter { $0.isJazzLab }
            
            var sections: [GroupedEventSection] = []
            
            if !main.isEmpty {
                sections.append(GroupedEventSection(type: .mainStage, events: main))
            }
            if !jazzLab.isEmpty {
                sections.append(GroupedEventSection(type: .jazzLab, events: jazzLab))
            }
            
            return GroupedEventsByDay(date: date, sections: sections)
        }
        .sorted { $0.date < $1.date }
    }
}
