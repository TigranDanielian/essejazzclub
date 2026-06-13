//
//  MenuCatalog.swift
//  Services
//

import Foundation

public struct MenuItem: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let descriptionHTML: String?
    public let pictureURL: String?
    public let price: Decimal
    public let categoryName: String

    public var formattedPrice: String {
        let number = NSDecimalNumber(decimal: price)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let value = formatter.string(from: number) ?? number.stringValue
        return "\(value) ₽"
    }
}

public struct MenuSection: Identifiable, Equatable {
    public let categoryName: String
    public let items: [MenuItem]

    public var id: String { categoryName }
}

public struct MenuCatalog: Equatable {
    public let sections: [MenuSection]

    public var categoryNames: [String] {
        sections.map(\.categoryName)
    }
}
