//
//  EventPriceView.swift
//  Services
//
//  Created by Tigran Danielian on 09.06.2025.
//

import SwiftUI
import Core

struct EventPriceView: View {
    @State private var price: String
    @State private var large: Bool
    
    init(price: String? = nil, large: Bool = false) {
        self.price = price ?? ""
        self.large = large
    }

    var body: some View {
        Text(price.isEmpty ? "FREE" : "\(price)")
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .font(.system(size: large ? 16 : 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color(uiColor: price.isEmpty ? Colors.freetag : Colors.softGold))
            .background(Color(uiColor: Colors.mainBackground))
            .cornerRadius(4)
    }
}

#Preview {
    EventPriceView(price: "1000")
}

extension EventPriceView {
    static var free: EventPriceView = .init()
}
