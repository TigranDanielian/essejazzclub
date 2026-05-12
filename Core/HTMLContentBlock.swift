//
//  HTMLContentBlock.swift
//  Core
//

import Foundation

/// Элемент HTML-страницы в порядке следования в разметке (для сборки экрана из секций).
public enum HTMLContentBlock: Equatable, Hashable, Sendable {
    /// HTML-фрагмент между картинками (можно передать в `htmlAttributed`).
    case text(String)
    case image(url: String)
}

public extension String {

    /// Разбивает HTML на чередование текстовых фрагментов и изображений по тегам `<img>`.
    ///
    /// Текст — подстроки исходного HTML (с тегами), без вставленных `<img>`.
    /// Для каждого `<img>` берётся `src`, иначе `data-src`, иначе `data-original`.
    func htmlContentBlocks() -> [HTMLContentBlock] {
        var blocks: [HTMLContentBlock] = []
        var cursor = startIndex

        while let imgStart = range(of: "<img", options: .caseInsensitive, range: cursor..<endIndex) {
            let textSlice = self[cursor..<imgStart.lowerBound]
            let textFragment = String(textSlice).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textFragment.isEmpty {
                blocks.append(.text(textFragment))
            }

            guard let tagEnd = self[imgStart.lowerBound...].firstIndex(of: ">") else {
                break
            }
            let tagRange = imgStart.lowerBound...tagEnd
            let tagString = String(self[tagRange])
            if let rawURL = Self.extractImageURL(from: tagString) {
                let normalized = rawURL.decodingBasicHTMLEntities().trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalized.isEmpty {
                    blocks.append(.image(url: normalized))
                }
            }

            cursor = index(after: tagEnd)
        }

        let tail = String(self[cursor...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            blocks.append(.text(tail))
        }

        return blocks
    }

    private static func extractImageURL(from imgTag: String) -> String? {
        if let u = firstAttributeMatch("src", in: imgTag) { return u }
        if let u = firstAttributeMatch("data-src", in: imgTag) { return u }
        if let u = firstAttributeMatch("data-original", in: imgTag) { return u }
        return nil
    }

    private static func firstAttributeMatch(_ name: String, in tag: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        let patterns = [
            "\(escaped)\\s*=\\s*\"([^\"]*)\"",
            "\(escaped)\\s*=\\s*'([^']*)'",
            "\(escaped)\\s*=\\s*([^\\s>]+)"
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let ns = tag as NSString
            let full = ns.length
            guard let match = regex.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: full)),
                  match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: tag)
            else { continue }
            let value = String(tag[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { return value }
        }
        return nil
    }

    fileprivate func decodingBasicHTMLEntities() -> String {
        var s = self
        let pairs: [(String, String)] = [
            ("&amp;", "&"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&#x2F;", "/"),
            ("&#47;", "/")
        ]
        for (enc, dec) in pairs {
            s = s.replacingOccurrences(of: enc, with: dec, options: .caseInsensitive)
        }
        return s
    }
}
