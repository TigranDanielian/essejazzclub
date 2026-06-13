//
//  ShopService.swift
//  Services
//
//  Created by Tigran Danielian on 27.05.2026.
//

import Foundation
import API
import Combine

public protocol ShopService {
    func load() -> AnyPublisher<Void, Error>
    
    func categories() -> AnyPublisher<[ShopCategory], Never>
    
    func products(categoryId: Int?) -> AnyPublisher<[ShopProduct], Error>
}

public final class ShopServiceImpl: ShopService {
    private let apiClient: ApiClient
    
    @Published private var _categories: [ShopCategory] = []
    
    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
    public func load() -> AnyPublisher<Void, any Error> {
        apiClient.requestModel(endpoint: .Shop.categories())
            .prefix(1)
            .handleEvents(receiveOutput: { [weak self] categories in
                self?._categories = categories
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    public func categories() -> AnyPublisher<[ShopCategory], Never> {
        $_categories.eraseToAnyPublisher()
    }
    
    public func products(categoryId: Int?) -> AnyPublisher<[ShopProduct], Error> {
        apiClient.requestModel(endpoint: .Shop.products(categoryId: categoryId))
            .eraseToAnyPublisher()
    }
    
}
