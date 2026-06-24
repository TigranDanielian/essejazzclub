//
//  ScheduleFilterScreen.swift
//  ScheduleFeature
//

import SwiftUI
import Core

public struct ScheduleFilterScreen: View {
    @ObservedObject private var viewModel: ScheduleFilterViewModel
    private let onDismiss: () -> Void

    public init(viewModel: ScheduleFilterViewModel, onDismiss: @escaping () -> Void) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var minimumDateTo: Date {
        max(startOfToday, viewModel.draft.dateFrom ?? startOfToday)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    filterSection(title: "Сцена") {
                        chipRow(ScheduleStageFilterOption.allCases) { option in
                            ScheduleFilterChip(
                                title: option.title,
                                isSelected: viewModel.draft.stageTypes.contains(option)
                            ) {
                                viewModel.toggleStage(option)
                            }
                        }
                    }

                    filterSection(title: "Стоимость") {
                        chipRow(SchedulePriceFilterOption.allCases) { option in
                            ScheduleFilterChip(
                                title: option.title,
                                isSelected: viewModel.draft.priceTypes.contains(option)
                            ) {
                                viewModel.togglePrice(option)
                            }
                        }
                    }

                    filterSection(title: "Дата") {
                        VStack(alignment: .leading, spacing: 12) {
                            dateToggleRow(
                                title: "От",
                                isEnabled: viewModel.draft.dateFrom != nil,
                                date: Binding(
                                    get: { viewModel.draft.dateFrom ?? startOfToday },
                                    set: { newValue in
                                        let date = Calendar.current.startOfDay(for: newValue)
                                        viewModel.draft.dateFrom = date
                                        if let dateTo = viewModel.draft.dateTo, dateTo < date {
                                            viewModel.draft.dateTo = date
                                        }
                                    }
                                ),
                                minimumDate: startOfToday,
                                onToggle: viewModel.setDateFromEnabled
                            )

                            dateToggleRow(
                                title: "До",
                                isEnabled: viewModel.draft.dateTo != nil,
                                date: Binding(
                                    get: { viewModel.draft.dateTo ?? minimumDateTo },
                                    set: { viewModel.draft.dateTo = Calendar.current.startOfDay(for: $0) }
                                ),
                                minimumDate: minimumDateTo,
                                onToggle: viewModel.setDateToEnabled
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(uiColor: Colors.mainBackground))
            .navigationTitle("Фильтр")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть", action: onDismiss)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Применить") {
                        viewModel.apply()
                        onDismiss()
                    }
                    .foregroundStyle(Color(uiColor: Colors.accentSheet))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.canReset {
                    Button("Сбросить фильтры") {
                        viewModel.reset()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(uiColor: Colors.accentSheet))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: Colors.mainBackground))
                }
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipRow<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) -> some View where Data.Element: Identifiable {
        FlowLayout(spacing: 8) {
            ForEach(data) { item in
                content(item)
            }
        }
    }

    private func dateToggleRow(
        title: String,
        isEnabled: Bool,
        date: Binding<Date>,
        minimumDate: Date,
        onToggle: @escaping (Bool) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: onToggle
            )) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(uiColor: Colors.text))
            }
            .tint(Color(uiColor: Colors.accentSheet))

            if isEnabled {
                DatePicker(
                    "",
                    selection: date,
                    in: minimumDate...Date.distantFuture,
                    displayedComponents: .date
                )
                .datePickerStyle(.automatic)
                .labelsHidden()
                .tint(Color(uiColor: Colors.accentSheet))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: Colors.cardBackground))
                .cornerRadius(12)
            }
        }
    }
}

private struct ScheduleFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(
                    isSelected
                        ? Color(uiColor: Colors.textOnAccent)
                        : Color(uiColor: Colors.text)
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? Color(uiColor: Colors.accentSheet)
                                : Color(uiColor: Colors.cardBackground)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

/// Простая обёртка для переноса чипов на следующую строку.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
