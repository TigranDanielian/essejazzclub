//
//  CalendarEventsManager.swift
//  Core
//
//  Created by Tigran Danielian on 30.06.2025.
//

import Foundation
import EventKit

public final class CalendarEventsManager: ObservableObject {
    public var events = [EKEvent]()
    let eventStore = EKEventStore()
    
    public init() {
        requestAccess()
    }
    
    func fetchEvent(date: Date) -> [EKEvent] {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
    
    public func requestAccess() {
        Task {
            _ = try? await authorizationStatus()
        }
    }
    
    func authorizationStatus() async throws -> Bool {
        return try await eventStore.requestAccess(to: .event)
    }
    
    func setEventDate(date: Date) async throws {
        let response = try await authorizationStatus()
        if response {
            self.events = fetchEvent(date: date)
        }
    }
    
    @MainActor
    public func addEvent(title: String, date: Date) async throws {
        let response = try await authorizationStatus()
        if response {
            let event = EKEvent(eventStore: eventStore)
            event.calendar = eventStore.defaultCalendarForNewEvents
            event.title = title
            event.startDate = date
            event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: date)!
            
            try eventStore.save(event, span: .thisEvent)
        }
    }
}

