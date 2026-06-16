//
//  EventPresentation.swift
//  SharedInfrastructure
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
    var bannerUrlString: String? { model.bannerUrl }
    var isJazzLab: Bool { model.type == .jazzLab }
    var date: Date { model.dateWithTimes.date }
    var isTop: Bool { model.isTop }

    var times: [String] {
        model.dateWithTimes.times.map {
            $0.time.formatted(date: .omitted, time: .shortened)
        }
    }

    var dateString: String {
        EventDateFormatting.formatDayMonth(date)
    }

    func dateString(format: String) -> String {
        EventDateFormatting.formatter(format: format).string(from: date)
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
            EventDateFormatting.calendarStartDate(day: model.dateWithTimes.date, time: $0.time)
        }
    }
}
