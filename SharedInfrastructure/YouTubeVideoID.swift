//
//  YouTubeVideoID.swift
//  SharedInfrastructure
//

import Foundation

enum YouTubeVideoID {
    static func extract(from string: String) -> String? {
        var trimmed = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'<>"))

        guard !trimmed.isEmpty else { return nil }

        if trimmed.range(of: #"^[a-zA-Z0-9_-]{11}$"#, options: .regularExpression) != nil {
            return trimmed
        }

        if trimmed.hasPrefix("//") {
            trimmed = "https:\(trimmed)"
        } else if !trimmed.lowercased().hasPrefix("http") {
            trimmed = "https://\(trimmed)"
        }

        guard let url = URL(string: trimmed), let host = url.host?.lowercased() else {
            return extractFromText(trimmed)
        }

        if host.contains("youtu.be") {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        guard host.contains("youtube.com") else { return nil }

        let path = url.path
        if path.contains("/embed/"), let id = url.pathComponents.last, !id.isEmpty, id != "embed" {
            return id
        }
        if path.contains("/shorts/"), let id = url.pathComponents.last, !id.isEmpty, id != "shorts" {
            return id
        }
        if path.contains("/live/"), let id = url.pathComponents.last, !id.isEmpty, id != "live" {
            return id
        }
        if let queryID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "v" })?
            .value,
           !queryID.isEmpty {
            return queryID
        }

        return extractFromText(trimmed)
    }

    private static func extractFromText(_ text: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:v=|/embed/|youtu\.be/|/shorts/)([a-zA-Z0-9_-]{11})"#
        ) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let idRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[idRange])
    }
}
