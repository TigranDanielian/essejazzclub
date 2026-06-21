//
//  DayView.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 03.07.2025.
//

import SwiftUI
import Core

public struct DayView<EventRow: View>: View {
    let title: String?
    let sections: [GroupedEventSection]
    @Binding var textWidth: CGFloat
    let eventViewProvider: (EventViewModel) -> EventRow

    public init(
        title: String? = nil,
        sections: [GroupedEventSection],
        textWidth: Binding<CGFloat>? = nil,
        @ViewBuilder eventViewProvider: @escaping (EventViewModel) -> EventRow
    ) {
        self.title = title
        self.sections = sections
        self.eventViewProvider = eventViewProvider
        _textWidth = textWidth ?? .constant(0)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .bold()
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .font(.title2)
                    .foregroundColor(Color(uiColor: Colors.text))
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: TextWidthPreferenceKey.self,
                                value: geo.size.width
                            )
                        }
                    )
                    .onPreferenceChange(TextWidthPreferenceKey.self) { value in
                        textWidth = value
                    }
            }

            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections.filter({ !$0.events.isEmpty })) { section in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(section.type.rawValue.uppercased())
                            .font(.headline)
                            .foregroundColor(.init(uiColor: Colors.accentSheet))

                        VStack(spacing: 12) {
                            ForEach(section.events) { event in
                                eventViewProvider(event)
                                    .id(event.id)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, title == nil ? 0 : 12)
            .padding(.horizontal, 8)
        }
    }
}

public struct TextWidthPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
