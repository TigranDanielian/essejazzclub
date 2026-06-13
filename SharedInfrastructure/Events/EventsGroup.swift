//
//  EventsGroup.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 03.07.2025.
//

import Foundation

public struct GroupedEventsByDay: Identifiable {
    public var id: String {
        date.formatted()
    }
    
    public let date: Date
    public let sections: [GroupedEventSection]
    
    public var dateString: String {
        EventDateFormatting.formatDayMonth(date)
    }
    
    public init(date: Date, sections: [GroupedEventSection]) {
        self.date = date
        self.sections = sections
    }
}

public struct GroupedEventSection: Identifiable {
    /// Стабильный идентификатор внутри дня (не более одной секции каждого типа на дату).
    public var id: String { type.rawValue }
    public let type: EventStageSection
    public let events: [EventViewModel]

    public init(type: EventStageSection, events: [EventViewModel]) {
        self.type = type
        self.events = events
    }
}

public enum EventStageSection: String {
    case mainStage = "Главная сцена, 2 этаж"
    case jazzLab = "Jazz Lab, 1 этаж"
}
