//
//  SkeletonView.swift
//  SharedInfrastructure
//
//  Created by AI on 03.12.2025.
//

import SwiftUI
import Core

struct SkeletonView: View {
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Rectangle()
            .fill(Color(uiColor: Colors.text))
            .opacity(opacity)
            .animation(
                Animation
                    .easeInOut(duration: 0.5)
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


