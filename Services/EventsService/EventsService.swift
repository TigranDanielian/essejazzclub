//
//  EventsService.swift
//  Services
//
//  Created by Tigran Danielian on 15.05.2025.
//

import Foundation
import Combine
import API

public struct EventsState {
    public let events: [EventModel]
}

public protocol EventsService {
    /// Loads all events from current date
    func load() -> AnyPublisher<Void, Error>

    /// Одна страница расписания (`GET event-schedule`).
    func fetchEventSchedule(page: Int, per: Int) -> AnyPublisher<PaginatedEventSchedule, Error>

    var state: AnyPublisher<EventsState, Never> { get }

    /// Модель из текущего кэша по идентификатору слота расписания (`eventOccurrenceIdentifier`).
    func eventModel(forOccurrenceIdentifier identifier: String) -> EventModel?
}

public final class EventsServiceImpl: EventsService {
    private struct IdAndDate: Hashable {
        let id: Int
        let date: Date
    }

    private var apiClient: ApiClient
    @Published private var events: [EventModel] = []

    public var state: AnyPublisher<EventsState, Never> {
        $events
            .map { EventsState(events: $0) }
            .eraseToAnyPublisher()
    }

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    public func eventModel(forOccurrenceIdentifier identifier: String) -> EventModel? {
        events.first { eventOccurrenceIdentifier(for: $0) == identifier }
    }

    public func load() -> AnyPublisher<Void, Error> {
        loadEvents()
            .prefix(1)
            .handleEvents(receiveOutput: { [weak self] events in
                self?.events = events
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func fetchEventSchedule(
        page: Int = 1,
        per: Int = PaginatedEventScheduleRequest.defaultPer
    ) -> AnyPublisher<PaginatedEventSchedule, Error> {
        let request = PaginatedEventScheduleRequest(page: page, per: per)
        return apiClient.requestModel(endpoint: .Events.schedule(page: request.page, per: request.per))
    }

    private func loadEvents() -> AnyPublisher<[EventModel], Error> {
        eventDates()
            .flatMap { [weak self] dates -> AnyPublisher<[EventModel], Error> in
                guard let self, !dates.isEmpty else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                let idsAndDates = Set(dates.map { IdAndDate(id: $0.eventId, date: $0.date) })

                let resultEventDates = idsAndDates.reduce(into: [RemoteEventDate]()) { result, value in
                    if let eventDate = dates.first(where: { $0.eventId == value.id && $0.date == value.date }) {
                        result.append(eventDate)
                    }
                }

                let sortedOccurrences = resultEventDates.sorted(by: { $0.date < $1.date })
                let uniqueEventIds = Array(Set(sortedOccurrences.map(\.eventId))).sorted()

                let remoteByIdRequests = uniqueEventIds.map { eventId -> AnyPublisher<(Int, RemoteEvent)?, Never> in
                    self.remoteEvent(id: eventId)
                        .map { Optional((eventId, $0)) }
                        .catch { _ in Just(nil) }
                        .eraseToAnyPublisher()
                }

                guard !remoteByIdRequests.isEmpty else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                return Publishers.MergeMany(remoteByIdRequests)
                    .collect()
                    .map { optionalPairs -> [EventModel] in
                        let pairs = optionalPairs.compactMap { $0 }
                        let remotes = Dictionary(uniqueKeysWithValues: pairs)
                        return sortedOccurrences.compactMap { eventDate in
                            guard let remote = remotes[eventDate.eventId] else { return nil }
                            return EventModel(remoteEvent: remote, dates: dates, currentDate: eventDate)
                        }
                    }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func eventDates() -> AnyPublisher<[RemoteEventDate], Error> {
        apiClient.requestModel(endpoint: .Events.dates())
    }
    
    private func remoteEvent(id: Int) -> AnyPublisher<RemoteEvent, Error> {
        apiClient.requestModel(endpoint: .Events.get(id: id))
    }
}

public extension EventModel {
    init(remoteEvent: RemoteEvent, dates: [RemoteEventDate], currentDate: RemoteEventDate) {
        let eventDates = dates.filter({
            $0.eventId == currentDate.eventId
        }).map(\.date)
        
        let datesWithTimes = Set(eventDates).map({ (date: Date) -> DateWithTimes in
            let times = dates.filter({
                $0.eventId == currentDate.eventId
                && $0.date == currentDate.date
            }).map({ Time(id: $0.id, time: $0.time, bookLink: $0.bookLink) })
            
            return DateWithTimes(id: currentDate.id, date: date, times: times)
        }).first(where: { $0.date == currentDate.date }) ?? .init(id: 0, date: Date(), times: [])
        
        self.id = "\(currentDate.eventId)"
        self.title = remoteEvent.title ?? "Unknown"
        self.description = remoteEvent.description
        self.text = remoteEvent.text
        self.dateWithTimes = datesWithTimes
        self.thumbnailUrl = remoteEvent.thumbnail
        self.bannerUrl = remoteEvent.image
        self.type = currentDate.isJazzLab ? .jazzLab : .main
        self.prices = currentDate.prices
        self.isTop = remoteEvent.inTop
        self.youTubeLinks = remoteEvent.youTubeLinks
        self.eventId = remoteEvent.id
        self.bookLink = currentDate.bookLink
    }
}
