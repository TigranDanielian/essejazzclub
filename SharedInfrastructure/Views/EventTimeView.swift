//
//  EventTimeView.swift
//  Services
//
//  Created by Tigran Danielian on 09.06.2025.
//

import SwiftUI
import Core

public struct EventTimeView: View {
    @State private var time: String
    @State private var large: Bool
    
    public init(time: String, large: Bool = false) {
        self.time = time
        self.large = large
    }

    public var body: some View {
        Text(time)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .font(.system(size: large ? 16 : 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color(uiColor: Colors.text))
            .background(Color(uiColor: Colors.mainBackground))
            .cornerRadius(4)
    }
}

#Preview {
    EventTimeView(time: "123")
}
