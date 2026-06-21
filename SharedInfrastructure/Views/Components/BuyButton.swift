//
//  BuyButton.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

struct BuyButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(uiColor: Colors.textOnAccent))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(uiColor: Colors.accent))
                .cornerRadius(8)
        }
    }
}
