//
//  HomeUpcomingMusiciansCarousel.swift
//  HomeFeature
//

import SwiftUI
import Core
import SharedInfrastructure

struct HomeUpcomingMusiciansCarousel: View {
    let musicians: [MusicianViewModel]
    let onMusicianDetails: (MusicianViewModel) -> Void

    var body: some View {
        Group {
            if musicians.isEmpty {
                EmptyView()
            } else {
                HomeScreenSection(title: HomeScreenViewModel.homeUpcomingMusiciansSectionTitle) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 16) {
                            ForEach(musicians, id: \.musicianId) { musician in
                                MusicianRowView(musician: musician) {
                                    onMusicianDetails(musician)
                                }
                                .frame(width: cardWidth(itemCount: musicians.count))
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func cardWidth(itemCount: Int) -> CGFloat {
        if itemCount == 1 {
            return min(UIScreen.screenWidth - 72, 120)
        }
        return 100
    }
}
