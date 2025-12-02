//
//  DayView.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 03.07.2025.
//

import SwiftUI
import Core

public struct DayView: View {
    let title: String
    let sections: [GroupedEventSection]
    @Binding var textWidth: CGFloat
    var eventViewProvider: (EventViewModel) -> any View
    
    public init(title: String, sections: [GroupedEventSection], textWidth: Binding<CGFloat>? = nil, eventViewProvider: @escaping (EventViewModel) -> any View) {
        self.title = title
        self.sections = sections
        _textWidth = textWidth ?? .constant(0)
        self.eventViewProvider = eventViewProvider
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                

            VStack(alignment: .leading, spacing: 2) {
                ForEach(sections) { section in
                    Text(section.type.rawValue.uppercased())
                        .font(.headline)
                        .foregroundColor(.init(uiColor: Colors.accentSheet))
                        .padding([.horizontal, .top], 8)
                    VStack(spacing: 12) {
                        ForEach(section.events) { event in
                            AnyView(eventViewProvider(event))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(8)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
