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
    
    public init(time: String) {
        self.time = time
    }

    public var body: some View {
        Text(time)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .font(.footnote)
            .foregroundStyle(Color(uiColor: Colors.text))
            .background(Color(uiColor: Colors.mainBackground))
            .cornerRadius(4)
    }
}

#Preview {
    EventTimeView(time: "123")
}
