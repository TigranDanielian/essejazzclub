//
//  EventCalendarCoordinator.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Combine
import Core
import UIKit

public final class EventCalendarCoordinator: ObservableObject {
    private let calendarManager: CalendarEventsManager

    public init(calendarManager: CalendarEventsManager) {
        self.calendarManager = calendarManager
    }

    @MainActor
    public func handleAction(with viewModel: EventViewModel) {
        if viewModel.times.count > 1 {
            presentTimeSelection(for: viewModel)
        } else {
            addEventToCalendar(event: viewModel, time: viewModel.times.first ?? "19:00")
        }
    }

    @MainActor
    public func addEventToCalendar(event: EventViewModel, time: String) {
        Task {
            do {
                let timeComponents = time.split(separator: ":").compactMap { Int(String($0)) }
                let hour = timeComponents.first ?? 20
                let minute = timeComponents.count > 1 ? timeComponents[1] : 0
                let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: event.date)
                try await calendarManager.addEvent(title: event.title, date: date ?? event.date)
                await MainActor.run {
                    Self.presentSuccessAlert()
                }
            } catch {
                await MainActor.run {
                    Self.presentErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    private func presentTimeSelection(for event: EventViewModel) {
        guard let presenter = Self.topViewController() else { return }
        let alert = UIAlertController(title: "Select time", message: nil, preferredStyle: .actionSheet)
        for item in event.times {
            alert.addAction(UIAlertAction(title: item, style: .default) { [weak self] _ in
                self?.addEventToCalendar(event: event, time: item)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        Self.configurePopover(for: alert, presenter: presenter)
        presenter.present(alert, animated: true)
    }

    private static func configurePopover(for alert: UIAlertController, presenter: UIViewController) {
        guard let popover = alert.popoverPresentationController else { return }
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        popover.permittedArrowDirections = []
    }

    private static func presentSuccessAlert() {
        guard let presenter = topViewController() else { return }
        let alert = UIAlertController(title: "Event added", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    private static func presentErrorAlert(message: String) {
        guard let presenter = topViewController() else { return }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    private static func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root = root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let windowScene = scene else { return nil }
        let root = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? windowScene.windows.first?.rootViewController
        return topViewController(from: root)
    }
}
