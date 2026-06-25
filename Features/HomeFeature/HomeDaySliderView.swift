//
//  HomeDaySliderView.swift
//  HomeFeature
//

import SwiftUI
import Core
import SharedInfrastructure

/// Секции дня как в `DayView`, но концерты в каждой секции — горизонтальный слайдер.
struct HomeDaySliderView: View {
    let sections: [GroupedEventSection]
    let uiFactory: any UIFactory
    let onEventDetails: (EventViewModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(sections.filter({ !$0.events.isEmpty })) { section in
                VStack(alignment: .leading, spacing: 14) {
                    Text(section.type.rawValue.uppercased())
                        .font(.headline)
                        .foregroundStyle(Color(uiColor: Colors.accentSheet))
                        .padding(.horizontal, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .center, spacing: 12) {
                            ForEach(section.events) { event in
                                AnyView(uiFactory.produce(unit: .event(event)))
                                    .environment(\.eventCardTap) {
                                        onEventDetails(event)
                                    }
                                    .frame(width: cardWidth(itemCount: section.events.count))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    private func cardWidth(itemCount: Int) -> CGFloat {
        if itemCount == 1 {
            return UIScreen.screenWidth - 72
        }
        return min(UIScreen.screenWidth * 0.92, 340)
    }
}
