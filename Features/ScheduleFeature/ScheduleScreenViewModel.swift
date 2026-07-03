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
    // MARK: - Published

    @Published private(set) var grouped: [GroupedEventsByDay] = []
    @Published var searchInputText: String = ""
    @Published public private(set) var filter = ScheduleEventFilter.empty
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var loadGeneration = 0

    @Published var selectedEvent: EventViewModel?

    // MARK: - Derived UI

    public var isFilterActive: Bool { filter.isActive }

    var isSearchActive: Bool {
        !normalizedSearchQuery.isEmpty
    }

    var isQueryActive: Bool {
        isFilterActive || isSearchActive
    }

    var listEmptyState: ScheduleListEmptyState? {
        guard !isLoading, grouped.isEmpty else { return nil }
        if isQueryActive {
            return .noMatchingResults
        }
        return loadedModels.isEmpty ? .noEvents : .noMatchingResults
    }

    var showPaginationFooter: Bool {
        hasMore && !isLoading
    }

    // MARK: - Dependencies

    private let eventsService: EventsService
    private let viewModelFactory: ViewModelFactory
    private let tabNavigation: ScheduleTabNavigating
    private let contextHandler: (EventContextButtonType) -> Void

    // MARK: - Schedule data

    private var loadedModels: [EventModel] = []
    private var eventViewModelCache: [String: EventViewModel] = [:]
    private var currentPage = 0

    private var prefetchTask: Task<Void, Never>?
    private var searchDebounceTask: Task<Void, Never>?

    private var normalizedSearchQuery: String {
        searchInputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Init

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

    // MARK: - Public API

    func setSearchInput(_ text: String) {
        guard searchInputText != text else { return }
        searchInputText = text
        rebuildGrouped()
        scheduleSearchPrefetch()
    }

    func clearSearchInput() {
        searchInputText = ""
        searchDebounceTask?.cancel()
        rebuildGrouped()
        schedulePrefetchIfNeeded()
    }

    func loadInitialIfNeeded() async {
        guard loadedModels.isEmpty, !isLoading else { return }
        await reload()
    }

    func refresh() async {
        await reload()
    }

    func loadMore() async {
        await appendNextPage()
    }

    public func openFilter() {
        tabNavigation.presentFilter(presentation: .sheet)
    }

    public func updateFilter(_ filter: ScheduleEventFilter) {
        self.filter = filter
        rebuildGrouped()
        schedulePrefetchIfNeeded()
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

    // MARK: - Reload

    private func reload() async {
        cancelPrefetch()
        isLoading = true
        loadGeneration += 1
        currentPage = 0
        hasMore = false
        loadedModels = []
        eventViewModelCache.removeAll()
        grouped = []

        do {
            try await fetchPage(1, replacesCache: true)
        } catch {
            grouped = []
        }

        isLoading = false
        schedulePrefetchIfNeeded()
    }

    // MARK: - Pagination

    private func appendNextPage() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            try await fetchPage(currentPage + 1, replacesCache: false)
        } catch {
            // сохраняем уже загруженный список
        }
    }

    private func fetchPage(_ page: Int, replacesCache: Bool) async throws {
        let response = try await fetchSchedule(
            page: page,
            per: PaginatedEventScheduleRequest.schedulePageSize
        )

        let pageModels = EventModel.mergedFromScheduleItems(response.items)
        loadedModels = replacesCache
            ? pageModels
            : EventModel.mergedCombined(loadedModels + pageModels)

        currentPage = response.page
        hasMore = response.hasMore
        rebuildGrouped()
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

    // MARK: - Prefetch for filter / search

    private func scheduleSearchPrefetch() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            schedulePrefetchIfNeeded()
        }
    }

    private func schedulePrefetchIfNeeded() {
        cancelPrefetch()
        guard isQueryActive, hasMore else { return }

        prefetchTask = Task {
            await prefetchRemainingPagesForActiveQuery()
        }
    }

    /// При активном фильтре/поиске отбор идёт на клиенте поверх постраничного API —
    /// догружаем все оставшиеся страницы, а не только пока список пустой.
    private func prefetchRemainingPagesForActiveQuery() async {
        var pagesFetched = 0
        let maxPages = 30

        while !Task.isCancelled, hasMore, pagesFetched < maxPages {
            pagesFetched += 1
            await appendNextPage()
        }
    }

    private func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
        searchDebounceTask?.cancel()
        searchDebounceTask = nil
    }

    // MARK: - Presentation

    private func rebuildGrouped() {
        let matchingModels = loadedModels.filter(matchesQuery)
        let viewModels = matchingModels.map(viewModel(for:))
        grouped = ScheduleEventGrouper.group(viewModels)
    }

    private func matchesQuery(_ model: EventModel) -> Bool {
        let query = normalizedSearchQuery
        if !query.isEmpty,
           !model.title.lowercased().contains(query.lowercased()) {
            return false
        }
        return filter.matches(model)
    }

    private func viewModel(for model: EventModel) -> EventViewModel {
        let key = eventOccurrenceIdentifier(for: model)
        if let cached = eventViewModelCache[key] {
            return cached
        }

        let viewModel = viewModelFactory.produce(
            unit: .event(hasContextMenu: true, hasDate: false, model)
        ) as! EventViewModel
        eventViewModelCache[key] = viewModel
        return viewModel
    }
}
