//
//  ScheduleEventRowInteraction.swift
//  ScheduleFeature
//

import SwiftUI

@MainActor
final class ScheduleEventRowInteraction: ObservableObject {
    @Published var offsetX: CGFloat = 0
    @Published var startOffsetX: CGFloat = 0

    func reset() {
        offsetX = 0
        startOffsetX = 0
    }
}
