//
//  ClubFavoriteEventSchedule.swift
//  ClubFeature
//

import Foundation
import Services
import SharedInfrastructure

enum ClubFavoriteEventSchedule {
    static func occurrencesSorted(forEventId eventId: String, in events: [EventModel]) -> [EventModel] {
        FavoriteEventSchedule.sortedOccurrences(forEventId: eventId, in: events)
    }

    /// Предстоящие слоты; если все в прошлом — показываем всё отсортированное.
    static func upcomingSubset(from sorted: [EventModel], calendar: Calendar = .current, now: Date = .init()) -> [EventModel] {
        FavoriteEventSchedule.upcomingPreferredSubset(from: sorted, calendar: calendar, now: now)
    }

    static func timesSummary(for model: EventModel) -> String {
        FavoriteEventSchedule.timesSummary(for: model)
    }

    static func allUpcomingOccurrences(forEventId eventId: String, in events: [EventModel]) -> [EventDetailUpcomingOccurrence] {
        FavoriteEventSchedule.allDetailUpcomingOccurrences(forEventId: eventId, in: events)
    }

    /// Ближайшие слоты для чипов в списке избранного (как слоты времени на деталке события).
    static func upcomingDateChips(for occurrences: [EventModel], maxCount: Int = 12) -> [(occurrenceId: String, label: String)] {
        FavoriteEventSchedule.upcomingDateChips(fromOccurrences: occurrences, maxCount: maxCount)
    }
}
