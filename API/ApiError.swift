//
//  ApiError.swift
//  API
//
//  Created by Tigran Danielian on 14.05.2025.
//

import Foundation

/// Детали ошибки декодирования JSON — сохраняем контекст для логов и UI.
public struct DecodingErrorDetails: Equatable, Sendable {
    public let kind: String
    public let codingPath: String
    public let debugDescription: String
    public let expectedType: String?
    public let missingKey: String?
    public let underlyingError: String?

    public var formattedMessage: String {
        var parts: [String] = []
        parts.append("[\(kind)]")
        if !codingPath.isEmpty {
            parts.append("path: \(codingPath)")
        }
        if let expectedType {
            parts.append("expected: \(expectedType)")
        }
        if let missingKey {
            parts.append("key: \(missingKey)")
        }
        parts.append(debugDescription)
        if let underlyingError {
            parts.append("underlying: \(underlyingError)")
        }
        return parts.joined(separator: " · ")
    }

    public static func from(_ error: DecodingError) -> DecodingErrorDetails {
        switch error {
        case .typeMismatch(let type, let context):
            return DecodingErrorDetails(
                kind: "typeMismatch",
                codingPath: codingPathString(context.codingPath),
                debugDescription: context.debugDescription,
                expectedType: String(describing: type),
                missingKey: nil,
                underlyingError: context.underlyingError?.localizedDescription
            )
        case .valueNotFound(let type, let context):
            return DecodingErrorDetails(
                kind: "valueNotFound",
                codingPath: codingPathString(context.codingPath),
                debugDescription: context.debugDescription,
                expectedType: String(describing: type),
                missingKey: nil,
                underlyingError: context.underlyingError?.localizedDescription
            )
        case .keyNotFound(let key, let context):
            return DecodingErrorDetails(
                kind: "keyNotFound",
                codingPath: codingPathString(context.codingPath),
                debugDescription: context.debugDescription,
                expectedType: nil,
                missingKey: key.stringValue,
                underlyingError: context.underlyingError?.localizedDescription
            )
        case .dataCorrupted(let context):
            return DecodingErrorDetails(
                kind: "dataCorrupted",
                codingPath: codingPathString(context.codingPath),
                debugDescription: context.debugDescription,
                expectedType: nil,
                missingKey: nil,
                underlyingError: context.underlyingError?.localizedDescription
            )
        @unknown default:
            return DecodingErrorDetails(
                kind: "unknown",
                codingPath: "",
                debugDescription: error.localizedDescription,
                expectedType: nil,
                missingKey: nil,
                underlyingError: nil
            )
        }
    }

    private static func codingPathString(_ path: [CodingKey]) -> String {
        path.map(\.stringValue).joined(separator: " → ")
    }
}

public enum ApiError: Error, Equatable, Sendable {
    case invalidURL(url: String?)
    case network(code: Int, message: String)
    case httpError(statusCode: Int, bodyPreview: String?)
    case invalidResponse(statusCode: Int?, message: String)
    case decoding(DecodingErrorDetails)
    case requestFailed(message: String)

    public static func from(decodingError: DecodingError) -> ApiError {
        .decoding(DecodingErrorDetails.from(decodingError))
    }
}

extension ApiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            if let url, !url.isEmpty {
                return "Некорректный URL: \(url)"
            }
            return "Некорректный URL"
        case .network(_, let message):
            return "Ошибка сети: \(message)"
        case .httpError(let statusCode, let bodyPreview):
            var message = "HTTP \(statusCode)"
            if let bodyPreview, !bodyPreview.isEmpty {
                message += "\n\(bodyPreview)"
            }
            return message
        case .invalidResponse(let statusCode, let reason):
            if let statusCode {
                return "Некорректный ответ (HTTP \(statusCode)): \(reason)"
            }
            return "Некорректный ответ: \(reason)"
        case .decoding(let details):
            return "Ошибка декодирования: \(details.formattedMessage)"
        case .requestFailed(let message):
            return "Запрос не выполнен: \(message)"
        }
    }
}
