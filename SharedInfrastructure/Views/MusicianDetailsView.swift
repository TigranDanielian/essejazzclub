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
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        Group {
                            if let image = viewModel.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(uiColor: Colors.cardBackground)
                            }
                        }

                        if viewModel.isLoadingImage {
                            SkeletonView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.photoHeight)
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
            
            Button(action: { actionHandler(.dismiss) }) {
                Image(systemName: "multiply")
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(uiColor: Colors.textInverted))
                    .background(Color(uiColor: Colors.mainBackground))
                    .cornerRadius(12)
                    .padding(8)
            }
        }
        .background(Color(uiColor: Colors.mainBackground))
        .onAppear {
            if let text = viewModel.text.htmlAttributed(font: .systemFont(ofSize: 14, weight: .medium), color: Colors.text) {
                attributedText = text
            }
        }
    }
}
