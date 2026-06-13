//
//  EventSchedulePage.swift
//  Services
//

import Foundation

/// Ответ `GET event-schedule`.
public struct PaginatedEventSchedule: Decodable {
    public let items: [EventScheduleItem]
    public let page: Int
    public let per: Int
    public let total: Int

    public var totalPages: Int {
        guard per > 0 else { return 0 }
        return (total + per - 1) / per
    }

    public var hasMore: Bool {
        page < totalPages
    }
}

/// Один слот расписания с вложенным событием.
public struct EventScheduleItem: Decodable {
    public let id: Int
    public let eventId: Int
    public let date: Date
    /// Время слота (из строки `"HH:mm"`, таймзона Москва).
    public let time: Date
    public let prices: [Price]?
    public let isJazzLab: Bool
    public let bookLink: String?
    let event: RemoteEvent

    private let pricesRaw: String
    private let jazzlab: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case date
        case time
        case pricesRaw = "prices"
        case jazzlab
        case bookLink
        case event
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        eventId = try container.decode(Int.self, forKey: .eventId)
        pricesRaw = try container.decode(String.self, forKey: .pricesRaw)
        jazzlab = try container.decodeIfPresent(Int.self, forKey: .jazzlab)
        bookLink = try container.decodeIfPresent(String.self, forKey: .bookLink)
        event = try container.decode(RemoteEvent.self, forKey: .event)

        isJazzLab = Bool(truncating: NSNumber(integerLiteral: jazzlab ?? 0))
        prices = getPricesArray(from: pricesRaw.base64Decoded()?.removingPercentEncoding ?? "")

        let dateString = try container.decode(String.self, forKey: .date)
        let timeString = try container.decode(String.self, forKey: .time)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        guard let parsedDate = isoFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Invalid ISO 8601 date"
            )
        }
        date = parsedDate

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Europe/Moscow")

        guard let parsedTime = timeFormatter.date(from: timeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .time,
                in: container,
                debugDescription: "Invalid time format"
            )
        }
        time = parsedTime
    }
}

public extension EventModel {
    init(scheduleItem: EventScheduleItem) {
        let remote = scheduleItem.event
        id = "\(scheduleItem.eventId)"
        title = remote.title ?? "Unknown"
        description = remote.description
        text = remote.text
        dateWithTimes = DateWithTimes(
            id: scheduleItem.id,
            date: scheduleItem.date,
            times: [Time(id: scheduleItem.id, time: scheduleItem.time)]
        )
        thumbnailUrl = remote.thumbnail
        bannerUrl = remote.image
        type = scheduleItem.isJazzLab ? .jazzLab : .main
        prices = scheduleItem.prices
        isTop = remote.inTop
        youTubeLinks = remote.youTubeLinks
        eventId = remote.id
        bookLink = scheduleItem.bookLink
    }
}
