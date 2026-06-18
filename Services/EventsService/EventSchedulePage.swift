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
            times: [Time(id: scheduleItem.id, time: scheduleItem.time, bookLink: scheduleItem.bookLink)]
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

    /// Слоты одного концерта в один день (и на одной сцене) — одна карточка с несколькими временами.
    static func mergedFromScheduleItems(_ items: [EventScheduleItem]) -> [EventModel] {
        mergedCombined(items.map(EventModel.init(scheduleItem:)))
    }

    static func mergedCombined(_ models: [EventModel]) -> [EventModel] {
        let calendar = Calendar.current

        struct Key: Hashable {
            let eventId: String
            let day: Date
            let isJazzLab: Bool
        }

        let grouped = Dictionary(grouping: models) { model in
            Key(
                eventId: model.id,
                day: calendar.startOfDay(for: model.dateWithTimes.date),
                isJazzLab: model.type == .jazzLab
            )
        }

        return grouped.values
            .map { mergeScheduleOccurrenceGroup($0) }
            .sorted {
                if $0.dateWithTimes.date != $1.dateWithTimes.date {
                    return $0.dateWithTimes.date < $1.dateWithTimes.date
                }
                if $0.type != $1.type {
                    return $0.type == .main
                }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
    }

    private static func mergeScheduleOccurrenceGroup(_ models: [EventModel]) -> EventModel {
        guard let first = models.first else {
            fatalError("mergeScheduleOccurrenceGroup requires at least one model")
        }
        guard models.count > 1 else { return first }

        let sortedSlots = models.sorted {
            if $0.dateWithTimes.date != $1.dateWithTimes.date {
                return $0.dateWithTimes.date < $1.dateWithTimes.date
            }
            let t0 = $0.dateWithTimes.times.first?.time ?? .distantPast
            let t1 = $1.dateWithTimes.times.first?.time ?? .distantPast
            return t0 < t1
        }

        var seenTimeIDs = Set<Int>()
        let mergedTimes = sortedSlots
            .flatMap(\.dateWithTimes.times)
            .sorted { $0.time < $1.time }
            .filter { seenTimeIDs.insert($0.id).inserted }

        let primarySlot = sortedSlots.first { $0.dateWithTimes.id == mergedTimes.first?.id }
            ?? sortedSlots[0]

        var merged = primarySlot
        merged.dateWithTimes = DateWithTimes(
            id: primarySlot.dateWithTimes.id,
            date: primarySlot.dateWithTimes.date,
            times: mergedTimes
        )
        return merged
    }
}
