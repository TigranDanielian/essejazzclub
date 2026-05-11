//
//  ClubFavoriteEventSchedule.swift
//  ClubFeature
//

import Foundation
import Services
import SharedInfrastructure

enum ClubFavoriteEventSchedule {
    static func occurrencesSorted(forEventId eventId: String, in events: [EventModel]) -> [EventModel] {
        events.filter { $0.id == eventId }.sorted { $0.dateWithTimes.date < $1.dateWithTimes.date }
    }

    /// Предстоящие слоты; если все в прошлом — показываем всё отсортированное.
    static func upcomingSubset(from sorted: [EventModel], calendar: Calendar = .current, now: Date = .init()) -> [EventModel] {
        let today = calendar.startOfDay(for: now)
        let upcoming = sorted.filter { calendar.startOfDay(for: $0.dateWithTimes.date) >= today }
        return upcoming.isEmpty ? sorted : upcoming
    }

    static func timesSummary(for model: EventModel) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let parts = model.dateWithTimes.times.map { formatter.string(from: $0.time) }
        return parts.isEmpty ? "—" : parts.joined(separator: ", ")
    }

    /// Слоты для блока «Ближайшие даты» на деталке (без текущего слота, чтобы не дублировать шапку).
    static func upcomingForDetail(
        forEventId eventId: String,
        in events: [EventModel],
        excludingCurrentOccurrenceIdentifier excluded: String
    ) -> [EventDetailUpcomingOccurrence] {
        let subset = upcomingSubset(from: occurrencesSorted(forEventId: eventId, in: events))
        return subset
            .filter { eventOccurrenceIdentifier(for: $0) != excluded }
            .map {
                EventDetailUpcomingOccurrence(
                    occurrenceIdentifier: eventOccurrenceIdentifier(for: $0),
                    date: $0.dateWithTimes.date,
                    timesSummary: timesSummary(for: $0)
                )
            }
    }

    static func listSubtitle(for occurrences: [EventModel]) -> String {
        let subset = upcomingSubset(from: occurrences)
        guard !subset.isEmpty else { return "Нет дат в афише" }
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ru_RU")
        dayFormatter.dateFormat = "d MMM"
        let pieces: [String] = subset.prefix(2).map { model in
            let d = dayFormatter.string(from: model.dateWithTimes.date)
            let t = timesSummary(for: model)
            return t == "—" ? d : "\(d), \(t)"
        }
        let rest = subset.count - pieces.count
        var text = pieces.joined(separator: " · ")
        if rest > 0 {
            text += " +\(rest)"
        }
        return text
    }
}
