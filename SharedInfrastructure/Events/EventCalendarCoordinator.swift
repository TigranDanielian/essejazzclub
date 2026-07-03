//
//  EventCalendarCoordinator.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Core
import UIKit

@MainActor
public final class EventCalendarCoordinator {
    private static let calendarNotes = "Концерт в ESSE Jazz Club"
    private static let eventDuration: TimeInterval = 2 * 60 * 60

    private let calendarManager: CalendarEventsManager
    private let toastPresenter: ToastPresenter

    public nonisolated init(calendarManager: CalendarEventsManager, toastPresenter: ToastPresenter) {
        self.calendarManager = calendarManager
        self.toastPresenter = toastPresenter
    }

    public func handleAction(with viewModel: EventViewModel) {
        if viewModel.calendarStartDates.count > 1 {
            presentTimeSelection(for: viewModel)
        } else if let startDate = viewModel.calendarStartDates.first {
            toggleEventInCalendar(event: viewModel, startDate: startDate)
        }
    }

    public func toggleEventInCalendar(event: EventViewModel, startDate: Date) {
        Task {
            do {
                let endDate = startDate.addingTimeInterval(Self.eventDuration)
                let added = try await calendarManager.toggleEvent(
                    title: event.title,
                    notes: Self.calendarNotes,
                    startDate: startDate,
                    endDate: endDate,
                    url: event.websiteURL
                )
                NotificationCenter.default.post(
                    name: .esseEventCalendarStateDidChange,
                    object: event.occurrenceIdentifier
                )
                toastPresenter.show(added ? "Добавлено в календарь" : "Удалено из календаря")
            } catch {
                toastPresenter.show("Не удалось обновить календарь")
            }
        }
    }

    private func presentTimeSelection(for event: EventViewModel) {
        guard let presenter = TopPresenter.topViewController() else { return }
        let alert = UIAlertController(title: "Выберите время", message: nil, preferredStyle: .actionSheet)
        for (index, label) in event.times.enumerated() {
            guard index < event.calendarStartDates.count else { continue }
            let startDate = event.calendarStartDates[index]
            let isInCalendar = calendarManager.isEventInCalendar(url: event.websiteURL, startDate: startDate)
            let title = isInCalendar ? "Удалить \(label)" : "Добавить \(label)"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.toggleEventInCalendar(event: event, startDate: startDate)
            })
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        TopPresenter.configurePopover(for: alert, presenter: presenter)
        presenter.present(alert, animated: true)
    }
}
