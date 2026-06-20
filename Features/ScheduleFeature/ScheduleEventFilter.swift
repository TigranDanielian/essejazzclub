//
//  ScheduleEventFilter.swift
//  ScheduleFeature
//

import Foundation
import SharedInfrastructure

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

        let calendar = Calendar.current
        let eventDay = calendar.startOfDay(for: event.date)

        if let dateFrom {
            if eventDay < calendar.startOfDay(for: dateFrom) { return false }
        }

        if let dateTo {
            if eventDay > calendar.startOfDay(for: dateTo) { return false }
        }

        return true
    }
}
