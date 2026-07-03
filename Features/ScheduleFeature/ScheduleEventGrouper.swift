//
//  ScheduleEventGrouper.swift
//  ScheduleFeature
//

import Foundation
import SharedInfrastructure

enum ScheduleEventGrouper {
    @MainActor
    static func group(_ viewModels: [EventViewModel]) -> [GroupedEventsByDay] {
        let groupedByDate = Dictionary(grouping: viewModels) { $0.date }

        return groupedByDate.map { date, events in
            let main = events.filter { !$0.isJazzLab }
            let jazzLab = events.filter { $0.isJazzLab }

            var sections: [GroupedEventSection] = []
            if !main.isEmpty {
                sections.append(GroupedEventSection(type: .mainStage, events: main))
            }
            if !jazzLab.isEmpty {
                sections.append(GroupedEventSection(type: .jazzLab, events: jazzLab))
            }

            return GroupedEventsByDay(date: date, sections: sections)
        }
        .sorted { $0.date < $1.date }
    }
}
