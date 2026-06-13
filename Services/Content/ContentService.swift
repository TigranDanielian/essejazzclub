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

    /// Каталог блюд из YML (пока — promo.jazzesse.ru).
    func menu() -> AnyPublisher<MenuCatalog, Error>
}

public final class ContentServiceImpl: ContentService {
    private static let menuYMLURL = URL(string: "https://promo.jazzesse.ru/tstore/yml/2f7dd8cc9163f904b165485d7b6950b0.yml")!
    private static let menuRequestUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

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

    public func menu() -> AnyPublisher<MenuCatalog, Error> {
        Deferred {
            Future { promise in
                Task {
                    do {
                        var request = URLRequest(
                            url: Self.menuYMLURL,
                            cachePolicy: .reloadIgnoringLocalCacheData,
                            timeoutInterval: 60
                        )
                        request.setValue(Self.menuRequestUserAgent, forHTTPHeaderField: "User-Agent")
                        let (data, response) = try await URLSession.shared.data(for: request)
                        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                            throw URLError(.badServerResponse)
                        }
                        let catalog = try MenuYMLParser.parse(data: data)
                        promise(.success(catalog))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
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
