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

    static func allUpcomingOccurrences(forEventId eventId: String, in events: [EventModel]) -> [EventDetailUpcomingOccurrence] {
        let subset = upcomingSubset(from: occurrencesSorted(forEventId: eventId, in: events))
        return subset.map {
            EventDetailUpcomingOccurrence(
                occurrenceIdentifier: eventOccurrenceIdentifier(for: $0),
                date: $0.dateWithTimes.date,
                timesSummary: timesSummary(for: $0)
            )
        }
    }

    private static let shortDayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd.MM"
        return f
    }()

    /// Ближайшие слоты для чипов в списке избранного (как слоты времени на деталке события).
    static func upcomingDateChips(for occurrences: [EventModel], maxCount: Int = 12) -> [(occurrenceId: String, label: String)] {
        let subset = upcomingSubset(from: occurrences)
        return subset.prefix(maxCount).map { model in
            (
                occurrenceId: eventOccurrenceIdentifier(for: model),
                label: shortDayMonthFormatter.string(from: model.dateWithTimes.date)
            )
        }
    }
}
