//
//  EventView.swift
//  Core
//
//  Created by Tigran Danielian on 02.07.2025.
//

import SwiftUI
import Core

public struct EventView: View {
    @ObservedObject public var viewModel: EventViewModel
    
    public init(viewModel: EventViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                Image(uiImage: viewModel.image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .background(Color.secondary)
                    .cornerRadius(8)

                EventInfoView(viewModel: viewModel)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .background(Color(uiColor: Colors.cardBackground))
            .cornerRadius(12)
            .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
            .shadow(radius: 8)
            
            if viewModel.hasContextMenu {
                Button(action: {
                    withAnimation {
                        viewModel.toggleOffset()
                    }
                }) {
                    Image(uiImage: UIImage(resource: .options).withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding(2)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                .padding(8)
            }
        }
    }
}
