//
//  MusicianDetailsView.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 08.05.2026.
//

import SwiftUI
import Core
import Services

public struct MusicianDetailsView: View {
    @ObservedObject var viewModel: MusicianViewModel
    private var actionHandler: MusicianActionHandler
    @State private var attributedText: AttributedString = .init()
    @State private var navTitleHidden: Bool = true

    private enum Layout {
        static let textHorizontalPadding: CGFloat = 12
    }
    
    public init(
        viewModel: MusicianViewModel,
        actionHandler: @escaping MusicianActionHandler
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    DetailHeroImageView(
                        image: viewModel.image,
                        isLoading: viewModel.isLoadingImage,
                        placeholderSystemName: "person.crop.circle"
                    )

                    Text(viewModel.name)
                        .bold()
                        .padding(.horizontal, Layout.textHorizontalPadding)
                        .padding(.top, 12)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(uiColor: Colors.text))
                    
                    Text(viewModel.description)
                        .padding(.horizontal, Layout.textHorizontalPadding)
                        .font(.title3)
                        .foregroundColor(Color(uiColor: Colors.text))

                    upcomingEventsSection
                    
                    GeometryReader { geo in
                        SeparatorView()
                            .padding(.top, 12)
                            .preference(key: TitleOffsetPreference.self, value: geo.frame(in: .scrollView).minY)
                    }
                    .onPreferenceChange(TitleOffsetPreference.self) { value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navTitleHidden = value > 44
                        }
                    }
                                        
                    ExpandableText(text: $attributedText, limit: 100)
                        .padding(12)
                        .font(.caption2)
                        .foregroundStyle(Color(uiColor: Colors.text))
                 
                    Spacer()
                }
            }
            .appScrollContentBackgroundHidden()

            HStack(spacing: 10) {
                FavoriteContextButton(
                    viewModel: viewModel.favoriteHeartButtonViewModel,
                    onTap: { actionHandler(.favorite(viewModel.favoriteStorageId)) }
                )
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
        }
        .background(Color(uiColor: Colors.mainBackground))
        .task(id: viewModel.id) {
            viewModel.loadImageIfNeeded()
            viewModel.loadUpcomingEventsIfNeeded()
            await loadAttributedBio()
        }
        .onDisappear {
            viewModel.cancelUpcomingEventsLoad()
        }
        .navigationTitle(navTitleHidden ? "" : viewModel.name)
        .navigationBarTitleDisplayMode(.automatic)
    }

    private func loadAttributedBio() async {
        guard let parsed = await HTMLBioFormatting.attributedString(from: viewModel.text) else { return }
        guard !Task.isCancelled else { return }
        attributedText = parsed
    }

    @ViewBuilder
    private var upcomingEventsSection: some View {
        if viewModel.isLoadingUpcomingEvents {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        } else if !viewModel.upcomingEvents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SeparatorView()
                Text("Ближайшие концерты")
                    .bold()
                    .font(.title2)
                    .foregroundColor(Color(uiColor: Colors.text))
                    .padding(.horizontal, Layout.textHorizontalPadding)

                VStack(spacing: 12) {
                    ForEach(viewModel.upcomingEvents) { event in
                        EventView(viewModel: event)
                            .environment(\.eventCardTap) {
                                actionHandler(.event(.navigation(.onEventDetails(
                                    event,
                                    heroTransitionSourceID: EventHeroTransitionSourceID.card(
                                        occurrenceIdentifier: event.occurrenceIdentifier
                                    )
                                ))))
                            }
                    }
                }
                .padding(.horizontal, Layout.textHorizontalPadding)
            }
            .padding(.top, 8)
        }
    }
}

private struct TitleOffsetPreference: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
