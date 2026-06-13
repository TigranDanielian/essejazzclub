//
//  FavoriteEventSchedule.swift
//  SharedInfrastructure
//

import Foundation
import Services

/// Общая логика слотов события по `eventId` для избранного и карточек.
public enum FavoriteEventSchedule {
    /// Ближайшие слоты для чипов дат в списке избранного (`dd.MM`), в порядке афиши.
    public static func upcomingDateChips(
        fromOccurrences sortedOccurrences: [EventModel],
        maxCount: Int = 12
    ) -> [(occurrenceId: String, label: String)] {
        let subset = upcomingPreferredSubset(from: sortedOccurrences)
        return subset.prefix(maxCount).map { model in
            (
                occurrenceId: eventOccurrenceIdentifier(for: model),
                label: EventDateFormatting.formatShortDayMonth(model.dateWithTimes.date)
            )
        }
    }

    public static func sortedOccurrences(forEventId eventId: String, in events: [EventModel]) -> [EventModel] {
        events.filter { $0.id == eventId }.sorted { $0.dateWithTimes.date < $1.dateWithTimes.date }
    }

    /// Предстоящие слоты; если все в прошлом — весь отсортированный список.
    public static func upcomingPreferredSubset(
        from sorted: [EventModel],
        calendar: Calendar = .current,
        now: Date = .init()
    ) -> [EventModel] {
        let today = calendar.startOfDay(for: now)
        let upcoming = sorted.filter { calendar.startOfDay(for: $0.dateWithTimes.date) >= today }
        return upcoming.isEmpty ? sorted : upcoming
    }

    /// Один слот для карточки избранного: ближайшая дата или любой из афиши (без дублирования по всем датам).
    public static func primaryOccurrence(
        forEventId eventId: String,
        in events: [EventModel],
        calendar: Calendar = .current,
        now: Date = .init()
    ) -> EventModel? {
        let occ = sortedOccurrences(forEventId: eventId, in: events)
        guard !occ.isEmpty else { return nil }
        return upcomingPreferredSubset(from: occ, calendar: calendar, now: now).first ?? occ.first
    }

    public static func timesSummary(for model: EventModel) -> String {
        EventDateFormatting.timesSummary(for: model)
    }

    /// Все ближайшие слоты для блока «Ближайшие даты» на деталке избранного.
    public static func allDetailUpcomingOccurrences(forEventId eventId: String, in events: [EventModel]) -> [EventDetailUpcomingOccurrence] {
        let subset = upcomingPreferredSubset(from: sortedOccurrences(forEventId: eventId, in: events))
        return subset.map {
            EventDetailUpcomingOccurrence(
                occurrenceIdentifier: eventOccurrenceIdentifier(for: $0),
                date: $0.dateWithTimes.date,
                timesSummary: timesSummary(for: $0)
            )
        }
    }
}
