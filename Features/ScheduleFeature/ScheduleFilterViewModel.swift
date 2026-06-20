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
        draft = appliedFilter
        self.onApply = onApply
    }

    public var canReset: Bool {
        draft.isActive
    }

    public func toggleStage(_ option: ScheduleStageFilterOption) {
        if draft.stageTypes.contains(option) {
            draft.stageTypes.remove(option)
        } else {
            draft.stageTypes.insert(option)
        }
    }

    public func togglePrice(_ option: SchedulePriceFilterOption) {
        if draft.priceTypes.contains(option) {
            draft.priceTypes.remove(option)
        } else {
            draft.priceTypes.insert(option)
        }
    }

    public func setDateFromEnabled(_ isEnabled: Bool) {
        if isEnabled {
            draft.dateFrom = draft.dateFrom ?? Calendar.current.startOfDay(for: Date())
        } else {
            draft.dateFrom = nil
        }
    }

    public func setDateToEnabled(_ isEnabled: Bool) {
        if isEnabled {
            draft.dateTo = draft.dateTo ?? draft.dateFrom ?? Calendar.current.startOfDay(for: Date())
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
        var normalized = draft
        let calendar = Calendar.current

        if let from = normalized.dateFrom {
            normalized.dateFrom = calendar.startOfDay(for: from)
        }
        if let to = normalized.dateTo {
            normalized.dateTo = calendar.startOfDay(for: to)
        }
        if let from = normalized.dateFrom, let to = normalized.dateTo, from > to {
            normalized.dateFrom = to
            normalized.dateTo = from
        }

        return normalized
    }
}
