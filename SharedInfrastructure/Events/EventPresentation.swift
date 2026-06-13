//
//  EventPresentation.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 13.06.2026.
//

import Foundation
import Services


/// Форматирование полей события для UI (даты, цены, слоты календаря).
struct EventPresentation {
    private let model: EventModel

    init(model: EventModel) {
        self.model = model
    }

    var title: String { model.title }
    var description: String { model.description }
    var text: String { model.text }
    var imageUrlString: String? { model.thumbnailUrl }
    var isJazzLab: Bool { model.type == .jazzLab }
    var date: Date { model.dateWithTimes.date }
    var isTop: Bool { model.isTop }

    var times: [String] {
        model.dateWithTimes.times.map {
            $0.time.formatted(date: .omitted, time: .shortened)
        }
    }

    var dateString: String {
        Self.displayDateFormatter.string(from: date)
    }

    func dateString(format: String) -> String {
        Self.makeDisplayDateFormatter(format: format).string(from: date)
    }

    var priceString: String? {
        guard let minPrice = model.prices?.map(\.price).min() else { return nil }
        return minPrice > 0 ? "от \(minPrice) ₽" : ""
    }

    var isFreeEvent: Bool {
        guard let minPrice = model.prices?.map(\.price).min() else { return false }
        return minPrice == 0
    }

    var bookingButtonTitle: String {
        isFreeEvent ? "Забронировать" : "Купить билет"
    }

    var calendarStartDates: [Date] {
        model.dateWithTimes.times.map {
            Self.calendarStartDate(day: model.dateWithTimes.date, time: $0.time)
        }
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()

    private static func makeDisplayDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }

    private static let moscowCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return calendar
    }()

    private static func calendarStartDate(day: Date, time: Date) -> Date {
        let parts = moscowCalendar.dateComponents([.hour, .minute], from: time)
        return moscowCalendar.date(
            bySettingHour: parts.hour ?? 20,
            minute: parts.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }
}
