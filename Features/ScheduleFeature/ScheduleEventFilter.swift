//
//  ScheduleEventFilter.swift
//  ScheduleFeature
//

import Foundation
import SharedInfrastructure
import Services

public enum ScheduleStageFilterOption: String, CaseIterable, Identifiable, Hashable {
    case mainStage
    case jazzLab

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .mainStage:
            return EventStageSection.mainStage.rawValue
        case .jazzLab:
            return EventStageSection.jazzLab.rawValue
        }
    }
}

public enum SchedulePriceFilterOption: String, CaseIterable, Identifiable, Hashable {
    case paid
    case free

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .paid:
            return "Платно"
        case .free:
            return "Бесплатно"
        }
    }
}

public struct ScheduleEventFilter: Equatable {
    public static let empty = ScheduleEventFilter()

    public var stageTypes: Set<ScheduleStageFilterOption> = []
    public var priceTypes: Set<SchedulePriceFilterOption> = []
    public var dateFrom: Date?
    public var dateTo: Date?

    public init(
        stageTypes: Set<ScheduleStageFilterOption> = [],
        priceTypes: Set<SchedulePriceFilterOption> = [],
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) {
        self.stageTypes = stageTypes
        self.priceTypes = priceTypes
        self.dateFrom = dateFrom
        self.dateTo = dateTo
    }

    public var isActive: Bool {
        !stageTypes.isEmpty || !priceTypes.isEmpty || dateFrom != nil || dateTo != nil
    }

    @MainActor
    public func matches(_ event: EventViewModel) -> Bool {
        if !stageTypes.isEmpty {
            let matchesStage =
                (stageTypes.contains(.mainStage) && !event.isJazzLab)
                || (stageTypes.contains(.jazzLab) && event.isJazzLab)
            if !matchesStage { return false }
        }

        if !priceTypes.isEmpty {
            let matchesPrice =
                (priceTypes.contains(.free) && event.isFreeEvent)
                || (priceTypes.contains(.paid) && !event.isFreeEvent)
            if !matchesPrice { return false }
        }

        return matchesDate(event.date)
    }

    public func matches(_ model: EventModel) -> Bool {
        if !stageTypes.isEmpty {
            let isJazzLab = model.type == .jazzLab
            let matchesStage =
                (stageTypes.contains(.mainStage) && !isJazzLab)
                || (stageTypes.contains(.jazzLab) && isJazzLab)
            if !matchesStage { return false }
        }

        if !priceTypes.isEmpty {
            let minPrice = model.prices?.map(\.price).min()
            let isFree = minPrice == 0
            let matchesPrice =
                (priceTypes.contains(.free) && isFree)
                || (priceTypes.contains(.paid) && !isFree)
            if !matchesPrice { return false }
        }

        return matchesDate(model.dateWithTimes.date)
    }

    private func matchesDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let eventDay = calendar.startOfDay(for: date)

        if let dateFrom {
            if eventDay < calendar.startOfDay(for: dateFrom) { return false }
        }

        if let dateTo {
            if eventDay > calendar.startOfDay(for: dateTo) { return false }
        }

        return true
    }
}
