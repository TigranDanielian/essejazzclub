//
//  MusiciansService.swift
//  Services
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Foundation
import API
import Combine

public protocol MusiciansService {
    /// Loads all musicians
    func load() -> AnyPublisher<Void, Error>
    
    func forEvent(id: Int) -> AnyPublisher<[Musician], Error>
    
    var state: AnyPublisher<MusiciansServiceImpl.State, Never> { get }
}

public final class MusiciansServiceImpl: MusiciansService {
    public func forEvent(id: Int) -> AnyPublisher<[Musician], Error> {
        state.tryMap({ state in
            let musicianIds = state.eventMusicians.filter({ $0.eventId == id }).map({ $0.musicianId })
            return state.musicians.filter({ musician in musicianIds.contains(where: { $0 == musician.id }) })
        })
        .eraseToAnyPublisher()
    }
    
    public func load() -> AnyPublisher<Void, Error> {
        getMusicians().zip(eventMusicians())
            .print()
            .map { _ in () }
            .eraseToAnyPublisher()
        
    }
    
    public struct State {
        let musicians: [Musician]
        let eventMusicians: [EventMusician]
    }
    
    private func getMusicians() -> AnyPublisher<[Musician], Error> {
        apiClient.requestModel(endpoint: .Musicians.musicians())
    }
    
    private func eventMusicians() -> AnyPublisher<[EventMusician], Error> {
        apiClient.requestModel(endpoint: .Musicians.eventMusicians())
    }
    
    private let apiClient: ApiClient
    
    @Published private var musiciansStore: [Musician] = []
    @Published private var eventMusiciansStore: [EventMusician] = []
    
    public var state: AnyPublisher<State, Never> {
        $musiciansStore.combineLatest($eventMusiciansStore)
            .map({ State(musicians: $0, eventMusicians: $1) })
            .eraseToAnyPublisher()
    }
    
    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
}
