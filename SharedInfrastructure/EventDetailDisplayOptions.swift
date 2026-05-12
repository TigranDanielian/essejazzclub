//
//  EventDetailDisplayOptions.swift
//  SharedInfrastructure
//

import Foundation

/// Настройки шапки и блока «Ближайшие даты» на экране деталей события.
public struct EventDetailDisplayOptions: Equatable {
    /// Дата и ряд времени поверх баннера (как на обычной деталке).
    public var showsHeroDateAndTimes: Bool
    /// Кнопка «Купить билет» на баннере.
    public var showsBuyTicketButton: Bool
    /// Тап по строке в «Ближайшие даты» обрабатывается снаружи (например, переход на другой слот).
    public var linksUpcomingOccurrences: Bool

    public init(
        showsHeroDateAndTimes: Bool,
        showsBuyTicketButton: Bool,
        linksUpcomingOccurrences: Bool
    ) {
        self.showsHeroDateAndTimes = showsHeroDateAndTimes
        self.showsBuyTicketButton = showsBuyTicketButton
        self.linksUpcomingOccurrences = linksUpcomingOccurrences
    }

    public static let `default` = EventDetailDisplayOptions(
        showsHeroDateAndTimes: true,
        showsBuyTicketButton: true,
        linksUpcomingOccurrences: false
    )

    /// Обзор по `eventId` из избранного клуба: без даты/времени и покупки в шапке; список слотов ведёт на выбранную дату.
    public static let clubFavoriteEventOverview = EventDetailDisplayOptions(
        showsHeroDateAndTimes: false,
        showsBuyTicketButton: false,
        linksUpcomingOccurrences: true
    )
}
