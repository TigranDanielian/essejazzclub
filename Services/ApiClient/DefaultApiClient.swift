//
//  DefaultApiClient.swift
//  Services
//
//  Created by Tigran Danielian on 15.05.2025.
//

import Foundation
import Combine
import API

public final class DefaultApiClient: ApiClient {
    private let baseURL: URL
    private let logger: Logger

    /// Таймаут и число повторных попыток только для `requestModel` (всего до 3 запросов при ошибке).
    private enum ModelRequestPolicy {
        static let timeoutInterval: TimeInterval = 10
        /// `retry(n)` в Combine — ещё n попыток после первой неудачи → всего `n + 1` запрос.
        static let retryCount = 2
    }
    
    public init(baseURL: URL, logger: ConsoleLogger = ConsoleLogger()) {
        self.baseURL = baseURL
        self.logger = logger
    }
    
    public func request(endpoint: ApiEndpoint) -> DataResponse {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            logger.log(response: nil, data: nil, error: ApiError.invalidURL)
            return Fail(error: ApiError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        
        logger.log(request: request)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(
                receiveOutput: { [weak self] data, response in
                    self?.logger.log(response: response, data: data, error: nil)
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.log(response: nil, data: nil, error: error)
                    }
                })
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    throw ApiError.invalidResponse
                }
                return data
            }
            .mapError { error in
                if error is URLError {
                    return ApiError.invalidURL
                } else {
                    return ApiError.requestFailed
                }
            }
            .eraseToAnyPublisher()
    }
    
    public func requestModel<Model>(endpoint: ApiEndpoint) -> ModelResponse<Model> where Model: Decodable {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true) else {
            logger.log(response: nil, data: nil, error: ApiError.invalidURL)
            return Fail(error: ApiError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = endpoint.method.rawValue.uppercased()
        request.timeoutInterval = ModelRequestPolicy.timeoutInterval
        
        // Обработка параметров
        if let task = endpoint.task {
            switch task {
            case .query(let parameters):
                let queryItems = parameters.compactMap { key, value -> URLQueryItem? in
                    guard let value = value else { return nil }
                    return URLQueryItem(name: key, value: String(describing: value))
                }
                urlComponents.queryItems = queryItems
                request.url = urlComponents.url
                
            case .json(let parameters):
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = parameters.compactMapValues { $0 }
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
            case .data(let data):
                request.httpBody = data
                
            case .formData(let fields):
                // Можно реализовать multipart при необходимости
                break
                
            case .download:
                // Пропускаем — другой метод
                break
            }
        }
        
        
        logger.log(request: request)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(
                receiveOutput: { [weak self] data, response in
                    self?.logger.log(response: response, data: data, error: nil)
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.log(response: nil, data: nil, error: error)
                    }
                })
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    throw ApiError.invalidResponse
                }
                return data
            }
            .mapError { error -> Error in
                if error is URLError {
                    return ApiError.invalidURL
                } else if let api = error as? ApiError {
                    return api
                } else {
                    return ApiError.requestFailed
                }
            }
            .retry(ModelRequestPolicy.retryCount)
            .decode(type: Model.self, decoder: JSONDecoder())
            .mapError { error in
                if error is URLError {
                    return ApiError.invalidURL
                } else if error is DecodingError {
                    return ApiError.decodingError
                } else {
                    return ApiError.requestFailed
                }
            }
            .eraseToAnyPublisher()
    }
}
