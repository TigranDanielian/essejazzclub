//
//  SeparatorView.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

public struct SeparatorView: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .frame(height: 5)
            .cornerRadius(5)
            .foregroundColor(Color(uiColor: Colors.separator))
            .padding(.horizontal, 20)
    }
}
