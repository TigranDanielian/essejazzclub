//
//  MusicianRowView.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

struct MusicianRowView: View {
    @ObservedObject var musician: MusicianViewModel
    var onSelect: () -> Void = { }

    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: musician.image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())

                if musician.isLoadingImage {
                    SkeletonView()
                        .frame(width: 72, height: 72)
                        .cornerRadius(36)
                }
            }
            .onAppear { musician.loadImageIfNeeded() }
            .onDisappear { musician.cancelImageLoad() }
            .onTapGesture {
                onSelect()
            }

            Text(musician.name)
                .frame(maxWidth: 100)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: Colors.text))
        }
    }
}
