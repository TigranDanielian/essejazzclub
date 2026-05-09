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
    private var onDismiss: () -> Void
    @State private var attributedText: AttributedString = .init()
    
    public init(
        viewModel: MusicianViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading) {
                    ZStack {
                        Image(uiImage: viewModel.image ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .clipped()
                            .cornerRadius(12)

                        if viewModel.isLoadingImage {
                            SkeletonView()
                                .cornerRadius(12)
                        }
                    }
                    .shadow(radius: 12)
                    
                    Text(viewModel.name)
                        .bold()
                        .padding(.horizontal, 12)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(uiColor: Colors.text))
                    
                    Text(viewModel.description)
                        .padding(.horizontal, 12)
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
            
            Button(action: { onDismiss() }) {
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
