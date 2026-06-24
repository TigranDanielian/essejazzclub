//
//  ScheduleFilterViewModel.swift
//  ScheduleFeature
//

import Foundation

@MainActor
public final class ScheduleFilterViewModel: ObservableObject {
    @Published public var draft: ScheduleEventFilter

    private let onApply: (ScheduleEventFilter) -> Void

    public init(
        appliedFilter: ScheduleEventFilter,
        onApply: @escaping (ScheduleEventFilter) -> Void
    ) {
        self.onApply = onApply
        draft = Self.normalized(appliedFilter)
    }

    public var canReset: Bool {
        draft.isActive
    }

    public func toggleStage(_ option: ScheduleStageFilterOption) {
        draft.stageTypes.removeAll()
        draft.stageTypes.insert(option)
    }

    public func togglePrice(_ option: SchedulePriceFilterOption) {
        draft.priceTypes.removeAll()
        draft.priceTypes.insert(option)
    }

    public func setDateFromEnabled(_ isEnabled: Bool) {
        if isEnabled {
            draft.dateFrom = draft.dateFrom.map { Self.clampedToMinimumDate($0) } ?? Self.startOfToday
        } else {
            draft.dateFrom = nil
        }
    }

    public func setDateToEnabled(_ isEnabled: Bool) {
        if isEnabled {
            let fallback = draft.dateFrom ?? Self.startOfToday
            draft.dateTo = draft.dateTo.map { Self.clampedToMinimumDate($0, minimum: fallback) } ?? fallback
        } else {
            draft.dateTo = nil
        }
    }

    public func apply() {
        onApply(normalizedDraft())
    }

    public func reset() {
        draft = .empty
        onApply(.empty)
    }

    private func normalizedDraft() -> ScheduleEventFilter {
        Self.normalized(draft)
    }

    private static var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private static func clampedToMinimumDate(_ date: Date, minimum: Date? = nil) -> Date {
        let calendar = Calendar.current
        let floor = calendar.startOfDay(for: minimum ?? startOfToday)
        return max(calendar.startOfDay(for: date), floor)
    }

    private static func normalized(_ filter: ScheduleEventFilter) -> ScheduleEventFilter {
        var normalized = filter
        let calendar = Calendar.current
        let today = startOfToday

        if let from = normalized.dateFrom {
            normalized.dateFrom = max(calendar.startOfDay(for: from), today)
        }
        if let to = normalized.dateTo {
            let minimumTo = normalized.dateFrom ?? today
            normalized.dateTo = max(calendar.startOfDay(for: to), minimumTo)
        }
        if let from = normalized.dateFrom, let to = normalized.dateTo, from > to {
            normalized.dateFrom = to
            normalized.dateTo = from
        }

        return normalized
    }
}
