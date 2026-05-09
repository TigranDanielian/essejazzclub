//
//  EventOccurrenceIdentifier.swift
//  Services
//

import Foundation

/// Стабильный идентификатор конкретной записи в расписании: событие + слот даты из API.
/// Одно и то же событие (`EventModel.id`) может иметь несколько записей с разными `dateWithTimes.id`.
public func eventOccurrenceIdentifier(for model: EventModel) -> String {
    "\(model.id):\(model.dateWithTimes.id)"
}
