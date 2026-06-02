//
//  MockApiClient.swift
//  Tests
//
//  Created by Tigran Danielian on 14.05.2025.
//

import Foundation
import Combine
import API

class MockAPIClient: ApiClient {
    var responseData: Data?
    var error: ApiError?

    func request(endpoint: ApiEndpoint) -> DataResponse {
        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let data = responseData else {
            return Fail(error: ApiError.invalidResponse(statusCode: nil, message: "No mock data")).eraseToAnyPublisher()
        }

        return Just(data)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func requestModel<Model>(endpoint: ApiEndpoint) -> ModelResponse<Model> where Model: Decodable {
        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let data = responseData else {
            return Fail(error: ApiError.invalidResponse(statusCode: nil, message: "No mock data")).eraseToAnyPublisher()
        }

        return Just(data)
            .decode(type: Model.self, decoder: JSONDecoder())
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    return ApiError.from(decodingError: decodingError)
                }
                return ApiError.requestFailed(message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}
