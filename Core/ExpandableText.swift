//
//  ExpandableText.swift
//  Core
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Foundation
import SwiftUI

public struct ExpandableText: View {
    @Binding public var text: AttributedString
    private var lineLimit: CGFloat // чтобы не было обрезки по умолчанию
    
    @State private var expanded = false
    @State private var isTruncated = false
    
    public init(text: Binding<AttributedString>, limit: CGFloat = 300) {
        self._text = text
        self.lineLimit = limit
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .frame(maxHeight: expanded ? .infinity : lineLimit, alignment: .top)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: TextHeightPreferenceKey.self,
                            value: geo.size.height
                        )
                    }
                )
                .onPreferenceChange(TextHeightPreferenceKey.self) { height in
                    isTruncated = height >= lineLimit
                }

            if isTruncated {
                Button(action: { expanded.toggle() }) {
                    Text(expanded ? "Свернуть" : "Развернуть")
                        .font(.caption)
                        .foregroundColor(Color(uiColor: Colors.accentSheet))
                }
            }
        }
    }
}

struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
