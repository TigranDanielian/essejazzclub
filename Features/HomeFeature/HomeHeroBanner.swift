//
//  HomeHeroBanner.swift
//  HomeFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

/// Герой-баннер внутри root `NavigationStack` (не в pushed destination).
public struct HomeHeroBanner: View {
    let events: [EventViewModel]
    let imageLoader: ImageLoader
    let isPlaybackActive: Bool
    let onDetails: (EventViewModel) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var loopIndex = 1
    @State private var selectedIndex = 0
    @State private var scrollRequest: HomeHeroStoryScrollRequest?
    @State private var segmentProgress: CGFloat = 0
    @State private var segmentStartedAt = Date()
    @State private var isPausedByInteraction = false

    public init(
        events: [EventViewModel],
        imageLoader: ImageLoader,
        isPlaybackActive: Bool = true,
        onDetails: @escaping (EventViewModel) -> Void
    ) {
        self.events = events
        self.imageLoader = imageLoader
        self.isPlaybackActive = isPlaybackActive
        self.onDetails = onDetails
    }

    private var isStoryPaused: Bool {
        !isPlaybackActive || scenePhase != .active || isPausedByInteraction
    }

    public var body: some View {
        Group {
            if events.count <= 1, let event = events.first {
                HomeHeroOverlaySlide(
                    event: event,
                    imageLoader: imageLoader,
                    onDetails: { onDetails(event) },
                    registersHeroTransitionSource: true
                )
            } else {
                HomeHeroStoryPager(
                    events: events,
                    imageLoader: imageLoader,
                    onDetails: onDetails,
                    loopIndex: $loopIndex,
                    logicalIndex: $selectedIndex,
                    scrollRequest: $scrollRequest,
                    onLogicalIndexChange: { _ in restartStorySegment() }
                )
            }
        }
        .overlay {
            if events.count > 1 {
                storyInteractionOverlay
            }
        }
        .overlay(alignment: .bottom) {
            if events.count > 1 {
                HomeHeroStoryProgressIndicator(
                    count: events.count,
                    selection: selectedIndex,
                    progress: segmentProgress
                )
                .padding(.horizontal, 16)
                .padding(.bottom, HomeHeroSheetLayout.storyProgressBottomInset)
            }
        }
        .onChange(of: events.count) { _, count in
            selectedIndex = 0
            loopIndex = 1
            if count > 1 {
                scrollRequest = HomeHeroStoryScrollRequest(
                    targetLoopIndex: 1,
                    animated: false,
                    id: UUID()
                )
            } else {
                scrollRequest = nil
            }
            restartStorySegment()
        }
        .onChange(of: isStoryPaused) { wasPaused, isPaused in
            if wasPaused, !isPaused {
                resumeStoryTiming()
            }
        }
        .task(id: storyPlaybackToken) {
            await runStoryPlayback()
        }
        .frame(height: HomeHeroSheetLayout.sliderHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .ignoresSafeArea(edges: .top)
    }

    private func requestScroll(to loopIndex: Int, animated: Bool) {
        scrollRequest = HomeHeroStoryScrollRequest(
            targetLoopIndex: loopIndex,
            animated: animated,
            id: UUID()
        )
    }

    private func goToPreviousStory() {
        guard events.count > 1 else { return }
        requestScroll(to: loopIndex - 1, animated: true)
    }

    private func goToNextStory() {
        guard events.count > 1 else { return }
        requestScroll(to: loopIndex + 1, animated: true)
    }

    private var storyInteractionOverlay: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goToPreviousStory() }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard events.indices.contains(selectedIndex) else { return }
                        onDetails(events[selectedIndex])
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goToNextStory() }
            }
            .frame(height: HomeHeroSheetLayout.sliderHeight * 0.55)

            Spacer(minLength: 0)
        }
        .simultaneousGesture(storyHoldToPauseGesture)
    }

    private var storyHoldToPauseGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPausedByInteraction {
                    isPausedByInteraction = true
                }
            }
            .onEnded { _ in
                isPausedByInteraction = false
            }
    }

    private var storyPlaybackToken: String {
        "\(selectedIndex)-\(events.count)-\(segmentStartedAt.timeIntervalSince1970)-\(isPlaybackActive)"
    }

    private func restartStorySegment() {
        segmentStartedAt = Date()
        segmentProgress = 0
    }

    private func resumeStoryTiming() {
        let duration = HomeHeroSheetLayout.storyDuration
        segmentStartedAt = Date().addingTimeInterval(-duration * Double(segmentProgress))
    }

    @MainActor
    private func runStoryPlayback() async {
        guard events.count > 1 else { return }

        let duration = HomeHeroSheetLayout.storyDuration

        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(33))
            guard isPlaybackActive, scenePhase == .active else { continue }
            guard !isPausedByInteraction else { continue }

            let elapsed = Date().timeIntervalSince(segmentStartedAt)
            let progress = min(elapsed / duration, 1)
            segmentProgress = progress

            if progress >= 1 {
                goToNextStory()
                return
            }
        }
    }
}

private struct HomeHeroStoryProgressIndicator: View {
    let count: Int
    let selection: Int
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< count, id: \.self) { index in
                HomeHeroStoryProgressSegment(
                    isCompleted: index < selection,
                    isCurrent: index == selection,
                    progress: progress
                )
            }
        }
    }
}

private struct HomeHeroStoryProgressSegment: View {
    let isCompleted: Bool
    let isCurrent: Bool
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.35))

                Capsule()
                    .fill(Color.white)
                    .frame(width: fillWidth(in: geo.size.width))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 3)
    }

    private func fillWidth(in totalWidth: CGFloat) -> CGFloat {
        if isCompleted { return totalWidth }
        if isCurrent { return totalWidth * progress }
        return 0
    }
}

struct HomeHeroOverlaySlide: View {
    let event: EventViewModel
    let imageLoader: ImageLoader
    let onDetails: () -> Void
    var registersHeroTransitionSource: Bool = true

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            posterBackground

            LinearGradient(
                colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.15)
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                Spacer()

                Text(event.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(uiColor: Colors.textInverted))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Text(event.dateString)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(uiColor: Colors.textInverted))
                        .multilineTextAlignment(.leading)

                    if !event.times.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(event.times, id: \.self) { time in
                                Text(time)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(uiColor: Colors.textInverted))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.18))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, UIScreen.safeAreaTop + 12)
            .padding(.bottom, 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDetails)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .top)
        .task(id: event.occurrenceIdentifier) {
            image = nil
            await loadPosterIfNeeded()
        }
    }

    @ViewBuilder
    private var posterBackground: some View {
        ZStack {
            Color(uiColor: Colors.cardBackground)

            if let image {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                }
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isLoadingImage {
                SkeletonView()
            }
        }
        .eventHeroTransitionSource(
            sourceID: EventHeroTransitionSourceID.banner(
                occurrenceIdentifier: event.occurrenceIdentifier
            ),
            isEnabled: registersHeroTransitionSource
        )
    }

    private func loadPosterIfNeeded() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }

        guard let path = event.imageUrlString, !path.isEmpty else { return }

        let maxPixelSize = UIScreen.screenWidth * UIScreen.main.scale
        image = await PathImageLoading.load(
            imageLoader: imageLoader,
            path: path,
            maxPixelSize: maxPixelSize
        )
    }
}
