//
//  EventDateFormatting.swift
//  SharedInfrastructure
//

import Foundation
import Services

enum EventDateFormatting {
    static let russianLocale = Locale(identifier: "ru_RU")

    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = russianLocale
        return formatter
    }()

    static let dayMonthWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, EEEE"
        formatter.locale = russianLocale
        return formatter
    }()

    static let shortDayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        formatter.locale = russianLocale
        return formatter
    }()

    static func formatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = russianLocale
        return formatter
    }

    static let moscowCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return calendar
    }()

    static func formatDayMonth(_ date: Date) -> String {
        dayMonth.string(from: date)
    }

    static func formatDayMonthWeekday(_ date: Date) -> String {
        dayMonthWeekday.string(from: date)
    }

    static func formatShortDayMonth(_ date: Date) -> String {
        shortDayMonth.string(from: date)
    }

    static func calendarStartDate(day: Date, time: Date) -> Date {
        let parts = moscowCalendar.dateComponents([.hour, .minute], from: time)
        return moscowCalendar.date(
            bySettingHour: parts.hour ?? 20,
            minute: parts.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }

    static func timesSummary(for model: EventModel) -> String {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let parts = model.dateWithTimes.times.map { formatter.string(from: $0.time) }
        return parts.isEmpty ? "—" : parts.joined(separator: ", ")
    }
}
