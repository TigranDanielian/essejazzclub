//
//  ContentPageModel.swift
//  Services
//
//  Created by Tigran Danielian on 12.05.2026.
//

import Foundation

public struct ContentPageModel: Codable {
    public let title: String
    public let id: Int
    public let text: String
    
    enum CodingKeys: String, CodingKey {
        case title = "name"
        case id
        case text = "content"
    }
}
