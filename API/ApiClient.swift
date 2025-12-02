//
//  ApiClient.swift
//  API
//
//  Created by Tigran Danielian on 14.05.2025.
//

import Foundation
import Combine

public typealias DataResponse = AnyPublisher<Data?, Error>
public typealias ModelResponse<T> = AnyPublisher<T, Error>
public typealias DownloadResponse = AnyPublisher<URL?, Error>

public protocol ApiClient {
    func request(endpoint: ApiEndpoint) -> DataResponse
    func requestModel<Model: Decodable>(endpoint: ApiEndpoint) -> ModelResponse<Model>
}

