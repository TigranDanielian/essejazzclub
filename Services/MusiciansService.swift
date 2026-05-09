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
    public func musician(forId id: Int) -> Musician? {
        musiciansStore.first { $0.id == id }
    }

    public func forEvent(id: String) -> AnyPublisher<[Musician], Never> {
        state.flatMap { state in
            self.eventMusicians(id: id)
                .map { eMusicians in
                    state.musicians.filter { musician in eMusicians.contains { musician.id == $0.musicianId } }
                }
                .replaceError(with: [])
        }
        .eraseToAnyPublisher()
//        .eraseToAnyPublisher()
    }
    
    public func load() -> AnyPublisher<Void, Error> {
        getMusicians()
            .catch { error in
                Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in self?.musiciansStore = $0 })
            .print()
            .map { _ in () }
            .eraseToAnyPublisher()
        
    }
    
    private func getMusicians() -> AnyPublisher<[Musician], Error> {
        apiClient.requestModel(endpoint: .Musicians.musicians())
    }
    
    private func eventMusicians(id: String) -> AnyPublisher<[EventMusician], Error> {
        apiClient.requestModel(endpoint: .Musicians.eventMusicians(eventId: id))
    }
    
    private let apiClient: ApiClient
    
    @Published private var musiciansStore: [Musician] = []
    
    public var state: AnyPublisher<MusiciansState, Never> {
        $musiciansStore
            .map({ MusiciansState(musicians: $0) })
            .eraseToAnyPublisher()
    }
    
    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
}
