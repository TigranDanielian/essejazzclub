//
//  HTMLBioFormatting.swift
//  SharedInfrastructure
//

import UIKit
import Core

public enum HTMLBioFormatting {
    public static let detailFont = UIFont.systemFont(ofSize: 14, weight: .medium)

    public static func attributedString(
        from html: String,
        color: UIColor = Colors.text
    ) async -> AttributedString? {
        let font = detailFont
        return await Task.detached(priority: .userInitiated) {
            html.htmlAttributed(font: font, color: color)
        }.value
    }
}
