//
//  CalendarEventsManager.swift
//  Core
//
//  Created by Tigran Danielian on 30.06.2025.
//

import Foundation
import EventKit

public extension Notification.Name {
    static let esseEventCalendarStateDidChange = Notification.Name("esseEventCalendarStateDidChange")
}

public final class CalendarEventsManager: ObservableObject {
    public var events = [EKEvent]()
    let eventStore = EKEventStore()

    private static let startDateMatchTolerance: TimeInterval = 120

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
        try await eventStore.requestAccess(to: .event)
    }

    func setEventDate(date: Date) async throws {
        let response = try await authorizationStatus()
        if response {
            self.events = fetchEvent(date: date)
        }
    }

    /// Ищет событие по URL слота (как на сайте) и времени начала.
    public func findEvent(url: URL, startDate: Date) -> EKEvent? {
        let windowStart = startDate.addingTimeInterval(-3600)
        let windowEnd = startDate.addingTimeInterval(3 * 3600)
        let predicate = eventStore.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: nil)
        let targetURL = url.absoluteString
        return eventStore.events(matching: predicate).first { event in
            guard event.url?.absoluteString == targetURL else { return false }
            return abs(event.startDate.timeIntervalSince(startDate)) < Self.startDateMatchTolerance
        }
    }

    public func isEventInCalendar(url: URL, startDate: Date) -> Bool {
        findEvent(url: url, startDate: startDate) != nil
    }

    public func isOccurrenceInCalendar(url: URL, startDates: [Date]) -> Bool {
        startDates.contains { isEventInCalendar(url: url, startDate: $0) }
    }

    @MainActor
    public func addEvent(
        title: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        url: URL
    ) async throws {
        let response = try await authorizationStatus()
        guard response else { return }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = endDate
        event.url = url

        try eventStore.save(event, span: .thisEvent)
        NotificationCenter.default.post(name: .esseEventCalendarStateDidChange, object: nil)
    }

    @MainActor
    public func removeEvent(url: URL, startDate: Date) async throws -> Bool {
        let response = try await authorizationStatus()
        guard response else { return false }
        guard let event = findEvent(url: url, startDate: startDate) else { return false }

        try eventStore.remove(event, span: .thisEvent)
        NotificationCenter.default.post(name: .esseEventCalendarStateDidChange, object: nil)
        return true
    }

    /// `true` — добавлено, `false` — удалено.
    @MainActor
    public func toggleEvent(
        title: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        url: URL
    ) async throws -> Bool {
        if findEvent(url: url, startDate: startDate) != nil {
            _ = try await removeEvent(url: url, startDate: startDate)
            return false
        }
        try await addEvent(
            title: title,
            notes: notes,
            startDate: startDate,
            endDate: endDate,
            url: url
        )
        return true
    }
}
