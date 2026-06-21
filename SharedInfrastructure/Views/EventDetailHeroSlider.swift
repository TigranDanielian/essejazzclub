//
//  EventDetailHeroSlider.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

enum EventDetailHeroSlide: Identifiable {
    case youtube(String)
    case photo

    var id: String {
        switch self {
        case .youtube(let videoID):
            return "youtube-\(videoID)"
        case .photo:
            return "photo"
        }
    }
}

struct EventDetailHeroSlider: View {
    @ObservedObject var viewModel: EventViewModel
    @State private var selectedSlideID: String?

    private var slides: [EventDetailHeroSlide] {
        let videoIDs = viewModel.youTubeVideoIDs
        if videoIDs.isEmpty {
            return [.photo]
        }
        
        return [.photo] + videoIDs.map { EventDetailHeroSlide.youtube($0) }
    }

    /// Как у прежнего `scaledToFit` по ширине карточки; пока нет картинки — 16:9.
    private var heroHeight: CGFloat {
        guard let image = viewModel.image, image.size.width > 0 else {
            return UIScreen.screenWidth * 9 / 16
        }
        return UIScreen.screenWidth * image.size.height / image.size.width
    }

    var body: some View {
        Group {
            if slides.count == 1, let slide = slides.first {
                slideView(slide, isActive: true)
            } else {
                TabView(selection: $selectedSlideID) {
                    ForEach(slides) { slide in
                        slideView(slide, isActive: selectedSlideID == slide.id)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .onAppear {
            if selectedSlideID == nil {
                selectedSlideID = slides.first?.id
            }
        }
        .onChange(of: slides.map(\.id)) { _, _ in
            if let selectedSlideID, slides.contains(where: { $0.id == selectedSlideID }) {
                return
            }
            selectedSlideID = slides.first?.id
        }
    }

    @ViewBuilder
    private func slideView(_ slide: EventDetailHeroSlide, isActive: Bool) -> some View {
        switch slide {
        case .youtube(let videoID):
            YouTubeEmbedPlayerView(videoID: videoID, isActive: isActive)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))

        case .photo:
            ZStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.isLoadingImage {
                    photoPlaceholder
                }

                if viewModel.isLoadingImage {
                    SkeletonView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                viewModel.loadImageIfNeeded()
            }
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color(uiColor: Colors.cardBackground)
            VStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                Text("Повотрить загрузку")
                    .font(.caption)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
