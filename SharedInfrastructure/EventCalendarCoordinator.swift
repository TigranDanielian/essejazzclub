//
//  EventCalendarCoordinator.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Foundation
import SwiftUI
import Core

public final class EventCalendarCoordinator: ObservableObject {
    private let calendarManager: CalendarEventsManager
    
    @Published public var selectedCalendarEvent: EventViewModel? = nil
    @Published public var showSuccessAlert: Bool = false
    @Published public var showErrorAlert: Bool = false
    @Published public var showTimeSelection: Bool = false
    
    public init(calendarManager: CalendarEventsManager) {
        self.calendarManager = calendarManager
    }

    @MainActor
    public func handleAction(with viewModel: EventViewModel) {
        if viewModel.times.count > 1 {
            showTimeSelection = true
            selectedCalendarEvent = viewModel
        } else {
            addEventToCalendar(event: viewModel, time: viewModel.times.first ?? "19:00")
        }
    }

    @MainActor
    public func addEventToCalendar(event: EventViewModel, time: String) {
        Task {
            do {
                var dateComponents = DateComponents()
                let timeComponents = time.split(separator: ":").map({ Int(String($0)) })
                dateComponents.hour = timeComponents.first ?? 20
                dateComponents.minute = timeComponents.last ?? 00
                let date = Calendar.current.date(bySettingHour: (timeComponents.first ?? 20) ?? 20, minute: (timeComponents.last ?? 00) ?? 00, second: 0, of: event.date)
                try await calendarManager.addEvent(title: event.title, date: date ?? event.date)
                showSuccessAlert = true
            } catch {
                self.showErrorAlert = true
            }
        }
    }
}
