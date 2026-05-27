//
//  SkeletonView.swift
//  SharedInfrastructure
//
//  Created by AI on 03.12.2025.
//

import SwiftUI
import Core

public struct SkeletonView: View {
    @State private var opacity: Double = 0.5
    
    public init() {}
    
    public var body: some View {
        Rectangle()
            .fill(Color(uiColor: Colors.text))
            .opacity(opacity)
            .animation(
                Animation
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: opacity
            )
            .onAppear {
                opacity = 1
            }
    }
}

#Preview {
    SkeletonView()
        .frame(width: 120, height: 120)
        .background(Color(uiColor: Colors.cardBackground))
}


