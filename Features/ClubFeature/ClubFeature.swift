//
//  ClubFeature.swift
//  API
//
//  Created by Tigran Danielian on 30.05.2025.
//

import SwiftUI
import Core

public struct ClubScreen: View {
    public init() {}
    
    private let bannerItems: [ClubBannerItem] = [
        .init(
            title: "С приложением выгодно!",
            subtitle: "Покажите это приложение в клубе и получите скидку 10%",
            imageName: "Logo_black_eng"
        ),
        .init(
            title: "Специальные мероприятия",
            subtitle: "Авторские сеты, фестивали и камерные концерты.",
            imageName: "Logo_black_eng"
        )
    ]
    
    private let gridItems: [ClubGridItem] = [
        .init(title: "Афиша", imageName: "club_grid_schedule"),
        .init(title: "Меню", imageName: "club_grid_menu"),
        .init(title: "О клубе", imageName: "club_grid_about"),
        .init(title: "Как добраться", imageName: "club_grid_location")
    ]
    
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // MARK: - Features slider
                    ClubFeaturesSlider(items: bannerItems)
                        .frame(height: 220)
//                        .padding(.horizontal, 8)
                    
                    // MARK: - Club essentials grid
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(gridItems) { item in
                            ClubGridTile(item: item)
                        }
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
            }
            .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
//            .navigationTitle("Клуб")
//            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Models

struct ClubBannerItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

struct ClubGridItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
}

// MARK: - Grid tile view

private struct ClubGridTile: View {
    let item: ClubGridItem
    
    var body: some View {
        VStack(spacing: 0) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(Color(uiColor: Colors.text))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(12)
        .shadow(radius: 6)
    }
}


#Preview {
    ClubScreen()
}
