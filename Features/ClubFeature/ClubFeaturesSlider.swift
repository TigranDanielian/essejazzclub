//
//  ClubFeaturesSlider.swift
//  ClubFeature
//
//  Created by Tigran Danielian on 25.11.2025.
//

import SwiftUI
import Core

struct ClubFeaturesSlider: View {
    let items: [ClubBannerItem]
    
    var body: some View {
        TabView {
            ForEach(items) { item in
                ZStack(alignment: .bottomLeading) {
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color(uiColor: Colors.textInverted))
                        
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color(uiColor: Colors.secondaryText))
                            .lineLimit(2)
                    }
                    .padding(16)
                }
                .background(Color(uiColor: Colors.cardBackground))
                .cornerRadius(16)
                .shadow(radius: 8)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
        }
        .cornerRadius(16)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

#Preview {
    ClubFeaturesSlider(
        items: [
            .init(
                title: "Лучшие джазовые вечера",
                subtitle: "Каждый день уникальная программа и живая музыка.",
                imageName: "club_banner_1"
            ),
            .init(
                title: "Лучшие джазовые вечера",
                subtitle: "Каждый день уникальная программа и живая музыка.",
                imageName: "club_banner_1"
            )
        ]
    )
    .frame(height: 200)
    .padding()
    .background(Color(uiColor: Colors.mainBackground))
}

