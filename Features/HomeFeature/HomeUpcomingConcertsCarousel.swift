//
//  HomeUpcomingConcertsCarousel.swift
//  HomeFeature
//

import SwiftUI
import Core
import SharedInfrastructure

struct HomeUpcomingConcertsCarousel: View {
    let sections: [GroupedEventSection]
    let uiFactory: any UIFactory
    let onEventDetails: (EventViewModel) -> Void

    private var hasEvents: Bool {
        sections.contains { !$0.events.isEmpty }
    }

    var body: some View {
        Group {
            if !hasEvents {
                Text("Пока нет ближайших концертов")
                    .font(.body)
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            } else {
                HomeScreenSection(title: "Афиша на неделю") {
                    HomeDaySliderView(
                        sections: sections,
                        uiFactory: uiFactory,
                        onEventDetails: onEventDetails
                    )
                }
            }
        }
    }
}
