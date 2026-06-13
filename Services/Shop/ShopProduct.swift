//
//  ShopProduct.swift
//  Services
//
//  Created by Tigran Danielian on 27.05.2026.
//

import Foundation

public struct ShopProduct: Equatable, Codable, Identifiable {
    public let id: Int
    public let categoryId: Int?
    public let name: String?
    public let content: String?
    public let price: String?
    public let image: String?
}
