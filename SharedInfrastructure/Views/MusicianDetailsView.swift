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

    private enum Layout {
        static let photoHeight: CGFloat = 240
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
                    ZStack {
                        Group {
                            if let image = viewModel.image {
                                GeometryReader { geo in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                                        .clipped()
                                }
                            } else {
                                Color(uiColor: Colors.cardBackground)
                            }
                        }

                        if viewModel.isLoadingImage {
                            SkeletonView()
                                .cornerRadius(12)
                        }
                    }
                    .shadow(radius: 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.photoHeight)
                    .cornerRadius(12)
                    .clipped()
                    .ignoresSafeArea(.container, edges: .horizontal)

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
                    
                    SeparatorView()
                    
                    ExpandableText(text: $attributedText, limit: 100)
                        .padding(12)
                        .font(.caption2)
                        .foregroundStyle(Color(uiColor: Colors.text))
                 
                    Spacer()
                }
            }
            .appScrollContentBackgroundHidden()

            HStack(spacing: 10) {
                EventContextButton(
                    viewModel: viewModel.favoriteButtonViewModel,
                    onTap: { actionHandler(.favorite(viewModel.favoriteStorageId)) }
                )
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
        }
        .background(Color(uiColor: Colors.mainBackground))
        .task(id: viewModel.id) {
            viewModel.loadImageIfNeeded()
            await loadAttributedBio()
        }
        .navigationTitle(viewModel.name)
        .navigationBarTitleDisplayMode(.automatic)
    }

    private func loadAttributedBio() async {
        let html = viewModel.text
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let color = Colors.text
        let parsed = await Task.detached(priority: .userInitiated) {
            html.htmlAttributed(font: font, color: color)
        }.value
        guard !Task.isCancelled else { return }
        if let parsed {
            attributedText = parsed
        }
    }
}
