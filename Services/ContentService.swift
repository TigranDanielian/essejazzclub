//
//  ContentService.swift
//  Services
//
//  Created by Tigran Danielian on 12.05.2026.
//

import Foundation
import Combine
import API

public protocol ContentService {
    func load() -> AnyPublisher<Void, Error>
    
    func page(id: ContentPageId) -> AnyPublisher<ContentPageModel?, Error>
    
    func pages() -> AnyPublisher<[ContentPageModel], Never>
}

public final class ContentServiceImpl: ContentService {
    private let apiClient: ApiClient
    
    @Published private var _pages: [ContentPageModel] = []
    
    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
    public func load() -> AnyPublisher<Void, any Error> {
        apiClient.requestModel(endpoint: .ContentPages.all())
            .prefix(1)
            .handleEvents(receiveOutput: { [weak self] pages in
                self?._pages = pages
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    public func page(id: ContentPageId) -> AnyPublisher<ContentPageModel?, Error> {
        apiClient.requestModel(endpoint: .ContentPages.get(id: id.rawValue))
            .eraseToAnyPublisher()
    }
    
    public func pages() -> AnyPublisher<[ContentPageModel], Never> {
        $_pages.eraseToAnyPublisher()
    }
}
    
public enum ContentPageId: Int {
    case club = 5
    case interior = 6
    case environment = 7
    case clubCard = 8
    case menu = 15
    case contacts = 19
    
}
