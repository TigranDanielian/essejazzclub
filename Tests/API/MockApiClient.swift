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
            return Fail(error: ApiError.invalidResponse).eraseToAnyPublisher()
        }
        
        return Just(data)
            .mapError { _ in ApiError.decodingError }
            .eraseToAnyPublisher()
    }
    
    func requestModel<Model>(endpoint: ApiEndpoint) -> ModelResponse<Model> where Model : Decodable {
        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        guard let data = responseData else {
            return Fail(error: ApiError.invalidResponse).eraseToAnyPublisher()
        }
        
        return Just(data)
            .decode(type: Model.self, decoder: JSONDecoder())
            .mapError { _ in ApiError.decodingError }
            .eraseToAnyPublisher()
    }
}
