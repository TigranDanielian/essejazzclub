//
//  EventDetailUpcomingOccurrence.swift
//  SharedInfrastructure
//

import Foundation

/// Дополнительный блок «ближайшие даты» на экране деталей (например, из избранного по `eventId`).
public struct EventDetailUpcomingOccurrence: Hashable, Identifiable {
    public let occurrenceIdentifier: String
    public let date: Date
    public let timesSummary: String

    public var id: String { occurrenceIdentifier }

    public init(occurrenceIdentifier: String, date: Date, timesSummary: String) {
        self.occurrenceIdentifier = occurrenceIdentifier
        self.date = date
        self.timesSummary = timesSummary
    }
}
