//
//  ShopCategory.swift
//  Services
//
//  Created by Tigran Danielian on 27.05.2026.
//

import Foundation

public struct ShopCategory: Equatable, Codable {
    public let id: Int
    public let parentId: Int
    public let name: String
}
