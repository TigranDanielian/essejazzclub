//
//  FavoriteConcertRow.swift
//  SharedInfrastructure
//

import Foundation

/// Чип даты (`dd.MM`) в плашке избранного концерта.
public struct FavoriteConcertDateChip: Identifiable, Hashable {
    public let id: String
    public let label: String

    public init(occurrenceIdentifier: String, label: String) {
        self.id = occurrenceIdentifier
        self.label = label
    }
}

/// Данные для плашки избранного концерта (главная, клуб и т.д.).
public struct FavoriteConcertRow: Identifiable, Hashable {
    public let id: String
    public let eventId: String
    public let title: String
    public let thumbnailUrl: String?
    public let primaryOccurrenceIdentifier: String
    public let dateChips: [FavoriteConcertDateChip]
    public let sortDate: Date

    public init(
        eventId: String,
        title: String,
        thumbnailUrl: String?,
        primaryOccurrenceIdentifier: String,
        dateChips: [FavoriteConcertDateChip],
        sortDate: Date
    ) {
        self.id = eventId
        self.eventId = eventId
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.primaryOccurrenceIdentifier = primaryOccurrenceIdentifier
        self.dateChips = dateChips
        self.sortDate = sortDate
    }
}
