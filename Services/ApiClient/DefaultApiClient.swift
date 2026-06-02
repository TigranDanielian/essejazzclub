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
            let error = ApiError.invalidURL(url: "\(baseURL.absoluteString)/\(endpoint.path)")
            logger.log(response: nil, data: nil, error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        logger.log(request: request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(receiveOutput: { [weak self] data, response in
                self?.logger.log(response: response, data: data, error: nil)
            })
            .tryMap { data, response in
                try Self.validateHTTPResponse(data: data, response: response)
            }
            .mapError(Self.mapTransportError)
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.log(response: nil, data: nil, error: error)
                }
            })
            .eraseToAnyPublisher()
    }

    public func requestModel<Model>(endpoint: ApiEndpoint) -> ModelResponse<Model> where Model: Decodable {
        let targetPath = baseURL.appendingPathComponent(endpoint.path).absoluteString

        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true),
              let initialURL = urlComponents.url else {
            let error = ApiError.invalidURL(url: targetPath)
            logger.log(response: nil, data: nil, error: error)
            return Fail(error: error).eraseToAnyPublisher()
        }

        var request = URLRequest(url: initialURL)
        request.httpMethod = endpoint.method.rawValue.uppercased()
        request.timeoutInterval = ModelRequestPolicy.timeoutInterval

        if let task = endpoint.task {
            switch task {
            case .query(let parameters):
                let queryItems = parameters.compactMap { key, value -> URLQueryItem? in
                    guard let value = value else { return nil }
                    return URLQueryItem(name: key, value: String(describing: value))
                }
                urlComponents.queryItems = queryItems
                guard let urlWithQuery = urlComponents.url else {
                    let error = ApiError.invalidURL(url: targetPath)
                    logger.log(response: nil, data: nil, error: error)
                    return Fail(error: error).eraseToAnyPublisher()
                }
                request.url = urlWithQuery

            case .json(let parameters):
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = parameters.compactMapValues { $0 }
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            case .data(let data):
                request.httpBody = data

            case .formData, .download:
                break
            }
        }

        logger.log(request: request)

        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(receiveOutput: { [weak self] data, response in
                self?.logger.log(response: response, data: data, error: nil)
            })
            .tryMap { data, response in
                try Self.validateHTTPResponse(data: data, response: response)
            }
            .mapError(Self.mapTransportError)
            .retry(ModelRequestPolicy.retryCount)
            .decode(type: Model.self, decoder: JSONDecoder())
            .mapError(Self.mapDecodingError)
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.log(response: nil, data: nil, error: error)
                }
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Error mapping

private extension DefaultApiClient {
    static func validateHTTPResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse(
                statusCode: nil,
                message: "Ответ не является HTTPURLResponse"
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ApiError.httpError(
                statusCode: httpResponse.statusCode,
                bodyPreview: bodyPreview(from: data)
            )
        }

        return data
    }

    static func bodyPreview(from data: Data, limit: Int = 500) -> String? {
        guard !data.isEmpty else { return nil }
        if let text = String(data: data, encoding: .utf8) {
            if text.count > limit {
                return String(text.prefix(limit)) + "…"
            }
            return text
        }
        return "[\(data.count) bytes, not UTF-8]"
    }

    static func mapTransportError(_ error: Error) -> ApiError {
        if let apiError = error as? ApiError {
            return apiError
        }
        if let urlError = error as? URLError {
            return .network(code: urlError.errorCode, message: urlError.localizedDescription)
        }
        return .requestFailed(message: error.localizedDescription)
    }

    static func mapDecodingError(_ error: Error) -> ApiError {
        if let decodingError = error as? DecodingError {
            return ApiError.from(decodingError: decodingError)
        }
        return mapTransportError(error)
    }
}
