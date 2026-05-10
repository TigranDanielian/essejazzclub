//
//  MusiciansService.swift
//  Services
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Foundation
import API
import Combine

public struct MusiciansState {
    let musicians: [Musician]
}

public protocol MusiciansService {
    /// Loads all musicians
    func load() -> AnyPublisher<Void, Error>
    
    func forEvent(id: String) -> AnyPublisher<[Musician], Never>

    func musician(forId id: Int) -> Musician?
    
    var state: AnyPublisher<MusiciansState, Never> { get }
}

public final class MusiciansServiceImpl: MusiciansService {
    private let apiClient: ApiClient

    @Published private var musiciansStore: [Musician] = []

    private let cacheLock = NSLock()

    /// Ответ `eventMusicians` по id события — один раз на id, дальше только свёртка с глобальным списком.
    private var eventLineupCache: [String: [EventMusician]] = [:]

    /// Разделение одного сетевого запроса между параллельными подписчиками на тот же `eventId`.
    private var lineupInflight: [String: AnyPublisher<[EventMusician], Never>] = [:]

    public func musician(forId id: Int) -> Musician? {
        musiciansStore.first { $0.id == id }
    }

    public func forEvent(id: String) -> AnyPublisher<[Musician], Never> {
        Publishers.CombineLatest(state, eventLineup(for: id))
            .map { musicState, eventLinks in
                Self.musicians(for: musicState.musicians, linkedTo: eventLinks)
            }
            .eraseToAnyPublisher()
    }

    private static func musicians(for catalog: [Musician], linkedTo eventLinks: [EventMusician]) -> [Musician] {
        catalog.filter { musician in
            eventLinks.contains { $0.musicianId == musician.id }
        }
    }

    /// Один запрос `eventMusicians(eventId)` на id; при обновлении `musiciansStore` повторных запросов нет.
    private func eventLineup(for eventId: String) -> AnyPublisher<[EventMusician], Never> {
        cacheLock.lock()
        if let cached = eventLineupCache[eventId] {
            cacheLock.unlock()
            return Just(cached).eraseToAnyPublisher()
        }
        if let inflight = lineupInflight[eventId] {
            cacheLock.unlock()
            return inflight
        }
        cacheLock.unlock()

        let shared = eventMusicians(id: eventId)
            .handleEvents(receiveOutput: { [weak self] links in
                self?.finishLineupFetchSuccess(eventId: eventId, links: links)
            })
            .catch { [weak self] _ -> Just<[EventMusician]> in
                // Ошибку не кэшируем — следующая подписка снова пойдёт в сеть.
                self?.clearLineupInflightOnly(eventId: eventId)
                return Just([])
            }
            .share()
            .eraseToAnyPublisher()

        cacheLock.lock()
        lineupInflight[eventId] = shared
        cacheLock.unlock()

        return shared
    }

    private func finishLineupFetchSuccess(eventId: String, links: [EventMusician]) {
        cacheLock.lock()
        eventLineupCache[eventId] = links
        lineupInflight.removeValue(forKey: eventId)
        cacheLock.unlock()
    }

    private func clearLineupInflightOnly(eventId: String) {
        cacheLock.lock()
        lineupInflight.removeValue(forKey: eventId)
        cacheLock.unlock()
    }
    
    public func load() -> AnyPublisher<Void, Error> {
        getMusicians()
            .catch { _ in
                Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in self?.musiciansStore = $0 })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    private func getMusicians() -> AnyPublisher<[Musician], Error> {
        apiClient.requestModel(endpoint: .Musicians.musicians())
    }
    
    private func eventMusicians(id: String) -> AnyPublisher<[EventMusician], Error> {
        apiClient.requestModel(endpoint: .Musicians.eventMusicians(eventId: id))
    }
    
    public var state: AnyPublisher<MusiciansState, Never> {
        $musiciansStore
            .map({ MusiciansState(musicians: $0) })
            .eraseToAnyPublisher()
    }
    
    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
}
