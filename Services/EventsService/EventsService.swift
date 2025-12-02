//
//  EventsService.swift
//  Services
//
//  Created by Tigran Danielian on 15.05.2025.
//

import Foundation
import Combine
import API

public protocol EventsService {
    /// Loads all events from current date
    func load() -> AnyPublisher<Void, Error>

    var state: AnyPublisher<EventsServiceImpl.State, Never> { get }
}

public final class EventsServiceImpl: EventsService {
    private struct IdAndDate: Hashable {
        let id: Int
        let date: Date
    }

    public struct State {
        public let events: [EventModel]
    }

    private var apiClient: ApiClient
    @Published private var events: [EventModel] = []

    public var state: AnyPublisher<State, Never> {
        $events
            .map { State(events: $0) }
            .eraseToAnyPublisher()
    }

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
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

                let requests = resultEventDates
                    .sorted(by: { $0.date < $1.date })
                    .compactMap { eventDate in
                        self.remoteEvent(id: eventDate.eventId)
                            .map { EventModel(remoteEvent: $0, dates: dates, currentDate: eventDate) }
                            .eraseToAnyPublisher()
                    }

                return Publishers.MergeMany(requests)
                    .collect()
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
            }).map({ Time(id: $0.id, time: $0.time ) })
            
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
    }
}
