//
//  HTMLBioFormatting.swift
//  SharedInfrastructure
//

import UIKit
import Core

enum HTMLBioFormatting {
    static let detailFont = UIFont.systemFont(ofSize: 14, weight: .medium)

    static func attributedString(
        from html: String,
        color: UIColor = Colors.text
    ) async -> AttributedString? {
        let font = detailFont
        return await Task.detached(priority: .userInitiated) {
            html.htmlAttributed(font: font, color: color)
        }.value
    }
}
