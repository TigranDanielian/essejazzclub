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
    
    private let eventsService: EventsService
    private let tabNavigation: ScheduleTabNavigating
    private let contextHandler: (EventContextButtonType) -> Void
    
    public init(
        eventsService: EventsService,
        viewModelFactory: ViewModelFactory,
        tabNavigation: ScheduleTabNavigating,
        contextHandler: @escaping (EventContextButtonType) -> Void
    ) {
        self.eventsService = eventsService
        self.tabNavigation = tabNavigation
        self.contextHandler = contextHandler
        eventsService.state
            .receive(on: DispatchQueue.main)
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
    
    func refresh() async {
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var cancellable: AnyCancellable?
                cancellable = eventsService.load()
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { _ in }
                    )
            }
        } catch {
            // Ошибка обрабатывается через state publisher
        }
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

    public func handleAction(_ action: ScheduleScreenAction) {
        switch action {
        case .event(let eventAction):
            applyEventActionParts(
                eventAction,
                applyNavigation: { tabNavigation.applyEventNavigation($0) },
                handleContextButton: contextHandler
            )
        case .musician(let musicianAction):
            tabNavigation.applyMusicianNavigation(musicianAction)
        case .filter:
            tabNavigation.presentFilter(presentation: .sheet)
        }
    }

    public func openFilter() {
        tabNavigation.presentFilter(presentation: .sheet)
    }
}
