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
    @Environment(\.dismiss) private var dismiss
    private var actionHandler: MusicianActionHandler
    @State private var attributedText: AttributedString = .init()

    private enum Layout {
        static let textHorizontalPadding: CGFloat = 12
        static let favoriteTopPadding: CGFloat = 8
        static let favoriteTrailingPadding: CGFloat = 16
    }
    
    public init(
        viewModel: MusicianViewModel,
        actionHandler: @escaping MusicianActionHandler
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                DetailHeroImageView(
                    image: viewModel.image,
                    isLoading: viewModel.isLoadingImage,
                    placeholderSystemName: "person.crop.circle",
                    layout: .edgeToTop
                )

                Text(viewModel.name)
                    .bold()
                    .padding(.horizontal, Layout.textHorizontalPadding)
                    .padding(.top, 12)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(uiColor: Colors.text))
                
                Text(viewModel.description)
                    .padding(.horizontal, Layout.textHorizontalPadding)
                    .font(.title3)
                    .foregroundColor(Color(uiColor: Colors.text))

                upcomingEventsSection
                
                SeparatorView()
                    .padding(.top, 12)
                                    
                ExpandableText(text: $attributedText, limit: 100)
                    .padding(12)
                    .padding(.trailing, 24)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .lineSpacing(2.2)
             
                Spacer()
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            HStack(alignment: .top) {
                backButton
                    .padding(.leading, 12)
                    .padding(.top, 8)

                Spacer()

                FavoriteContextButton(
                    viewModel: viewModel.favoriteHeartButtonViewModel,
                    onTap: { actionHandler(.favorite(viewModel.favoriteStorageId)) },
                    backgroundStyle: .material
                )
                .padding(.top, Layout.favoriteTopPadding)
                .padding(.trailing, Layout.favoriteTrailingPadding)
            }
        }
        .appScrollContentBackgroundHidden()
        .background(Color(uiColor: Colors.mainBackground))
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("")
        .task(id: viewModel.id) {
            viewModel.loadImageIfNeeded()
            viewModel.loadUpcomingEventsIfNeeded()
            await loadAttributedBio()
        }
        .onDisappear {
            viewModel.cancelImageLoad()
            viewModel.cancelUpcomingEventsLoad()
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Назад")
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
