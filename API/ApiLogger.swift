//
//  ApiLogger.swift
//  API
//
//  Created by Tigran Danielian on 30.05.2025.
//

import Foundation

public protocol Logger {
    func log(request: URLRequest)
    func log(response: URLResponse?, data: Data?, error: Error?)
}

public final class ConsoleLogger: Logger {
    public init() {}

    public func log(request: URLRequest) {
        print("➡️ Request:")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }

    public func log(response: URLResponse?, data: Data?, error: Error?) {
        print("⬅️ Response:")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
            print("URL: \(httpResponse.url?.absoluteString ?? "nil")")
        }
        
        if let data = data {
            if let prettyJSON = formatJSON(data: data) {
                print("Body :\n\(prettyJSON)")
            } else if let responseBody = String(data: data, encoding: .utf8) {
                print("Body (raw):\n\(responseBody)")
            }
        }
        
        if let error = error {
            if let apiError = error as? ApiError {
                print("❌ Error: \(apiError.localizedDescription)")
            } else {
                print("❌ Error: \(error.localizedDescription)")
            }
        }
    }
}

private func formatJSON(data: Data) -> String? {
    do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        return String(data: prettyData, encoding: .utf8)
    } catch {
        return nil
    }
}
