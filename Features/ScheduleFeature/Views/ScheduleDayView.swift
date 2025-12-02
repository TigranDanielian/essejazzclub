//
//  DayCardView.swift
//  ScheduleFeature
//
//  Created by Tigran Danielian on 16.06.2025.
//

import SwiftUI
import Core
import SharedInfrastructure

struct ScheduleDayView: View {
    let eventsDay: GroupedEventsByDay
    let actionHandler: EventActionHandler
    @State private var textWidth: CGFloat = 0
    let uiFactory: any UIFactory

    var body: some View {
        ZStack(alignment: .topLeading) {
            TopLeftCutoutShape(
                cutoutSize: CGSize(width: textWidth, height: 36),
                cornerRadius: 12
            )
            .fill(Color(uiColor: Colors.altBackground), style: FillStyle(eoFill: true))
            .cornerRadius(12)
            
            DayView(title: eventsDay.dateString, sections: eventsDay.sections, textWidth: $textWidth) { eventViewModel in
                ScheduleEventView(
                    viewModel: eventViewModel,
                    onSelect: actionHandler,
                    uiFactory: uiFactory
                )
            }
        }
    }
}

struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
