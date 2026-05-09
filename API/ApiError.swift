//
//  ApiError.swift
//  API
//
//  Created by Tigran Danielian on 14.05.2025.
//

import Foundation

public enum ApiError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingError
    
//    public var localizedDescription: String {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL"
//        case .requestFailed:
//            return "Request failed: \(super.localizedDescription)"
//        case .invalidResponse:
//            return "Invalid response"
//        case .decodingError:
//            if let error = error as? DecodingError {
//                switch error {
//                case .typeMismatch(let any, let context):
//                    return "Decoding error: Type mismatch: \(any), \(context.debugDescription), \(context.codingPath)"
//                case .valueNotFound(let any, let context):
//                    return "Decoding error: Value not found: \(any), \(context.debugDescription)"
//                case .keyNotFound(let codingKey, let context):
//                    return "Decoding error: Key not found: \(codingKey), \(context.debugDescription)"
//                case .dataCorrupted(let context):
//                    return "Decoding error: Data corrupted: \(context.debugDescription)"
//                @unknown default:
//                    return "Decoding error: Unknown error"
//                }
//            }
//            
//            return "Decoding error: \(error.localizedDescription)"
//        }
//    }
}
