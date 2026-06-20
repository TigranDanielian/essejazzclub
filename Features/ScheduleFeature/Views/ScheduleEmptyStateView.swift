//
//  ScheduleEmptyStateView.swift
//  ScheduleFeature
//

import SwiftUI
import Core

struct ScheduleEmptyStateView: View {
    let state: ScheduleListEmptyState

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.system(size: 44))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var symbolName: String {
        switch state {
        case .noMatchingResults:
            return "magnifyingglass"
        case .noEvents:
            return "calendar"
        }
    }

    private var title: String {
        switch state {
        case .noMatchingResults:
            return "Ничего не нашлось :("
        case .noEvents:
            return "Пока нет мероприятий"
        }
    }

    private var subtitle: String? {
        switch state {
        case .noMatchingResults:
            return "Попробуйте изменить запрос или сбросить фильтры."
        case .noEvents:
            return "Потяните вниз, чтобы обновить."
        }
    }
}
