//
//  EventWebsiteLink.swift
//  SharedInfrastructure
//

import Foundation

public enum EventWebsiteLink {
    public static let baseURL = URL(string: "https://jazzesse.ru")!

    /// Пример: `https://jazzesse.ru/event/index/3604/8395`
    public static func url(eventId: Int, occurrenceId: Int) -> URL {
        baseURL
            .appendingPathComponent("event")
            .appendingPathComponent("index")
            .appendingPathComponent(String(eventId))
            .appendingPathComponent(String(occurrenceId))
    }

    public static func resolveBookingURL(from string: String?) -> URL? {
        guard let raw = string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.hasPrefix("//") {
            return URL(string: "https:" + raw)
        }
        if let url = URL(string: raw), url.scheme != nil {
            return url
        }
        return URL(string: raw, relativeTo: baseURL)?.absoluteURL
    }
}
