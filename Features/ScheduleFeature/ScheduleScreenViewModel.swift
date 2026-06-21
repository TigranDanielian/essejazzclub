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
    @Published var searchInputText: String = ""
    @Published public private(set) var filter = ScheduleEventFilter.empty
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var loadGeneration = 0

    @Published var selectedEvent: EventViewModel?

    public var isFilterActive: Bool { filter.isActive }

    var isSearchActive: Bool {
        !searchInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var listEmptyState: ScheduleListEmptyState? {
        guard !isLoading, grouped.isEmpty else { return nil }
        if isSearchActive || isFilterActive {
            return .noMatchingResults
        }
        if loadedModels.isEmpty {
            return .noEvents
        }
        return .noMatchingResults
    }

    var showPaginationFooter: Bool {
        hasMore && (!grouped.isEmpty || isFilterActive || isSearchActive)
    }

    private var loadedModels: [EventModel] = []
    private var currentPage = 0
    private var isFetchingPage = false
    private var searchFetchTask: Task<Void, Never>?

    private let eventsService: EventsService
    private let viewModelFactory: ViewModelFactory
    private let tabNavigation: ScheduleTabNavigating
    private let contextHandler: (EventContextButtonType) -> Void

    public init(
        eventsService: EventsService,
        viewModelFactory: ViewModelFactory,
        tabNavigation: ScheduleTabNavigating,
        contextHandler: @escaping (EventContextButtonType) -> Void
    ) {
        self.eventsService = eventsService
        self.viewModelFactory = viewModelFactory
        self.tabNavigation = tabNavigation
        self.contextHandler = contextHandler
    }

    func setSearchInput(_ text: String) {
        guard searchInputText != text else { return }
        searchInputText = text
        applyFilterAndGroup()
        scheduleFilteredResultsFetch()
    }

    func clearSearchInput() {
        searchInputText = ""
        searchFetchTask?.cancel()
        applyFilterAndGroup()
    }

    func loadInitialIfNeeded() async {
        guard loadedModels.isEmpty, !isFetchingPage else { return }
        await reload()
    }

    func reload() async {
        guard !isFetchingPage else { return }
        isFetchingPage = true
        isLoading = true
        loadGeneration += 1
        currentPage = 0
        hasMore = false
        loadedModels = []
        grouped = []

        do {
            try await appendPage(1)
        } catch {
            grouped = []
        }

        isLoading = false
        isFetchingPage = false
        await fetchMorePagesIfFilteredResultsEmpty()
    }

    func refresh() async {
        await reload()
    }

    func loadMore() async {
        guard hasMore, !isFetchingPage, !isLoading else { return }
        isFetchingPage = true
        isLoadingMore = true
        defer {
            isLoadingMore = false
            isFetchingPage = false
        }

        do {
            try await appendPage(currentPage + 1)
        } catch {
            // сохраняем уже загруженный список
        }
    }

    private func appendPage(_ page: Int) async throws {
        let response = try await fetchSchedule(
            page: page,
            per: PaginatedEventScheduleRequest.schedulePageSize
        )

        let pageModels = EventModel.mergedFromScheduleItems(response.items)
        loadedModels = page == 1
            ? pageModels
            : EventModel.mergedCombined(loadedModels + pageModels)

        currentPage = response.page
        hasMore = response.hasMore
        applyFilterAndGroup()
    }

    private func fetchSchedule(page: Int, per: Int) async throws -> PaginatedEventSchedule {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            var cancellable: AnyCancellable?

            cancellable = eventsService.fetchEventSchedule(page: page, per: per)
                .sink(
                    receiveCompletion: { completion in
                        defer { cancellable?.cancel() }
                        guard !didResume else { return }
                        if case .failure(let error) = completion {
                            didResume = true
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume(returning: value)
                    }
                )
        }
    }

    private func scheduleFilteredResultsFetch() {
        searchFetchTask?.cancel()
        searchFetchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await fetchMorePagesIfFilteredResultsEmpty()
        }
    }

    private func fetchMorePagesIfFilteredResultsEmpty() async {
        guard isFilterActive || isSearchActive else { return }

        var attempts = 0
        while grouped.isEmpty, hasMore, attempts < 10 {
            attempts += 1
            await loadMore()
        }
    }

    private func applyFilterAndGroup() {
        let query = searchInputText.trimmingCharacters(in: .whitespacesAndNewlines)

        let viewModels = loadedModels.map { model in
            viewModelFactory.produce(
                unit: .event(hasContextMenu: true, hasDate: false, model)
            ) as! EventViewModel
        }

        let filtered = viewModels.filter { viewModel in
            if !query.isEmpty,
               !viewModel.title.lowercased().contains(query.lowercased()) {
                return false
            }
            return filter.matches(viewModel)
        }
        groupEvents(filtered)
    }

    private func groupEvents(_ viewModels: [EventViewModel]) {
        let groupedByDate = Dictionary(grouping: viewModels) { $0.date }

        grouped = groupedByDate.map { (date, events) in
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

    public func updateFilter(_ filter: ScheduleEventFilter) {
        self.filter = filter
        applyFilterAndGroup()
        Task { await fetchMorePagesIfFilteredResultsEmpty() }
    }
}
