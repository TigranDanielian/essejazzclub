//
//  FavoritesStorage.swift
//  Core
//
//  Created by Tigran Danielian on 16.06.2025.
//

import Foundation
import Combine

public final class FavoritesStorage<Value: Hashable & Codable>: ObservableObject {
    private typealias FavoritesStorageCollection = [FavoritesStorageKey: [Value]]

    private var defaults: UserDefaults = .init(suiteName: "com.unity.esseJazzClub-favorites")!
    @Published private var storage: FavoritesStorageCollection = [:]
    private let defaultsKey = "EJC_Favorites"
    
    public init() {
        if let data = defaults.value(forKey: defaultsKey) as? Data,
           let decoded = try? JSONDecoder().decode(FavoritesStorageCollection.self, from: data) {
            storage = decoded
        }
    }
    
    public func add(_ value: Value, forKey key: FavoritesStorageKey) {
        if var array = storage[key] {
            array.append(value)
            storage[key] = array
        } else {
            storage[key] = [value]
        }
        
        updateDefaults()
    }
    
    public func remove(_ value: Value, forKey key: FavoritesStorageKey) {
        if var array = storage[key] {
            if let index = array.firstIndex(where: { $0 == value }) {
                array.remove(at: index)
            }
            storage[key] = array
        }
        
        updateDefaults()
    }
    
    public func isFavorite(_ value: Value, forKey key: FavoritesStorageKey) -> Bool {
        storage[key]?.contains(value) ?? false
    }
    
    public func isFavoritePublisher(for value: Value, key: FavoritesStorageKey) -> AnyPublisher<Bool, Never> {
        $storage
            .map { storage in
                storage[key]?.contains(value) ?? false
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    
    private func updateDefaults() {
        let value = try? JSONEncoder().encode(storage)
        defaults.setValue(value, forKey: defaultsKey)
        defaults.synchronize()
    }
    
    public func toggleState(forValue value: Value, forKey key: FavoritesStorageKey) {
        if isFavorite(value, forKey: key) {
            remove(value, forKey: key)
        } else {
            add(value, forKey: key)
        }
    }
    
    public func allFavorites(forKey key: FavoritesStorageKey) -> AnyPublisher<[Value], Never> {
        $storage
            .map { storage in
                storage[key] ?? []
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
        
    }
}

public enum FavoritesStorageKey: Hashable, Codable {
    case events
    case musicians
}
