//
//  ApiEndpoint.swift
//  API
//
//  Created by Tigran Danielian on 14.05.2025.
//

import Foundation

public struct ApiEndpoint {
    init(
        method: ApiEndpoint.Method,
        path: String,
        isAuthorizationRequired: Bool = true,
        task: ApiEndpoint.Task? = nil
    ) {
        self.path = path
        self.method = method
        self.isAuthorizationRequired = isAuthorizationRequired
        self.task = task
    }
    
    public let path: String
    public let method: Method
    public let isAuthorizationRequired: Bool
    public let task: Task?
    
    public enum Method: String {
        case get, post, delete, patch, put
    }
    
    public enum Task {
        case data(Data)
        case query(_ parameters: [String: Any?])
        case json([String: Any?])
        case formData(_ fields: [String: Any?])
        case download(newFileUrl: URL, options: DownloadOptions = .removePreviousFile)
        
        public enum DownloadOptions {
            case createIntermediateDirectories
            case removePreviousFile
        }
    }
}

