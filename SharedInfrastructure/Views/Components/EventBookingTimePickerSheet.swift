//
//  EventBookingTimePickerSheet.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

struct EventBookingTimePickerPresentation: Identifiable {
    let id = UUID()
    let slots: [EventBookingSlot]
    let bookingTitle: String
}

struct EventBookingTimePickerSheet: View {
    let slots: [EventBookingSlot]
    let onSelect: (EventBookingSlot) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(slots) { slot in
                Button {
                    dismiss()
                    onSelect(slot)
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                        Text(slot.timeLabel)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color(uiColor: Colors.text))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .scrollDisabled(true)
            .appScrollContentBackgroundHidden()
            .background(Color(uiColor: Colors.mainBackground))
            .navigationTitle("Выберите время")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.3)])
        .presentationDragIndicator(.visible)
    }
}
