//
//  String.swift
//  Core
//
//  Created by Tigran Danielian on 08.07.2025.
//

import UIKit

public extension String {
     func htmlAttributed(font: UIFont, color: UIColor, linkColor: UIColor = Colors.accent) -> AttributedString? {
        return htmlAttributed(family: font.familyName,
                              size: font.pointSize,
                              color: color,
                              linkColor: linkColor)
    }
    
    func htmlAttributed(family: String?,
                               size: CGFloat,
                               color: UIColor,
                               linkColor: UIColor) -> AttributedString? {

        do {
            let htmlCSSString = """
            <style>
                div  {
                    font-family: -apple-system;
                    font-size: \(size);
                    color: #\(color.hexString!);
                    white-space: pre-wrap;
                    line-height: 1.4;
                }
                a, a:link, a:visited {
                    color: #\(linkColor.hexString!);
                }
            </style>
            <div>\(self)</div>
            """
            
            guard let data = htmlCSSString.data(using: String.Encoding.utf8) else {
                return nil
            }
            
            let result = try NSMutableAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )

            let fullRange = NSRange(location: 0, length: result.length)
            result.enumerateAttribute(.link, in: fullRange) { value, range, _ in
                guard value != nil else { return }
                result.addAttribute(.foregroundColor, value: linkColor, range: range)
            }
            
            return try AttributedString(result, including: \.uiKit)
        } catch {
            print(error)
            return nil
        }
    }
}
