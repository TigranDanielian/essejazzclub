//
//  String.swift
//  Core
//
//  Created by Tigran Danielian on 08.07.2025.
//

import UIKit

public extension String {
     func htmlAttributed(font: UIFont, color: UIColor) -> AttributedString? {
        return htmlAttributed(family: font.familyName,
                              size: font.pointSize,
                              color: color)
    }
    
    func htmlAttributed(family: String?,
                               size: CGFloat,
                               color: UIColor) -> AttributedString? {

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
            
            return try AttributedString(result, including: \.uiKit)
        } catch {
            print(error)
            return nil
        }
    }
}
