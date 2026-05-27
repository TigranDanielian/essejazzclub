//
//  ClubMusiciansScreen.swift
//  ClubFeature
//
//  Created by Tigran Danielian on 16.05.2026.
//

import Combine
import Foundation
import SwiftUI
import Services
import SharedInfrastructure
import Core

private enum ClubMusiciansGridLayout {
    /// Отступ слева и справа от края экрана.
    static let screenEdgeInset: CGFloat = 12
    /// Расстояние между двумя колонками.
    static let columnSpacing: CGFloat = 12

    static var cellWidth: CGFloat {
        let totalWidth = UIScreen.screenWidth
        // две равные колонки: (ширина − левый отступ − правый − промежуток) / 2
        return (totalWidth - screenEdgeInset * 2 - columnSpacing) / 2
    }
}

/// Фиксированные размеры карточки: фото в отдельном прямоугольнике, плашка снизу — без вылезания картинки.
private enum MusicianGridItemLayout {
    static let cardHeight: CGFloat = 240
    static let infoBarHeight: CGFloat = 80
    static var imageSlotHeight: CGFloat { cardHeight - infoBarHeight }
}

public struct ClubMusiciansScreenDependencies {
    public let musiciansService: MusiciansService
    public let favoritesStorage: FavoritesStorage<String>
    public let imageLoader: ImageLoader
    public let viewModelFactory: ViewModelFactory
    public let uiFactory: any UIFactory

    public init(
        musiciansService: MusiciansService,
        favoritesStorage: FavoritesStorage<String>,
        imageLoader: ImageLoader,
        viewModelFactory: ViewModelFactory,
        uiFactory: any UIFactory
    ) {
        self.musiciansService = musiciansService
        self.favoritesStorage = favoritesStorage
        self.imageLoader = imageLoader
        self.viewModelFactory = viewModelFactory
        self.uiFactory = uiFactory
    }
}

public struct ClubMusiciansScreen: View {
    @StateObject private var viewModel: ClubMusiciansScreenViewModel
    private let uiFactory: any UIFactory

    public init(dependencies: ClubMusiciansScreenDependencies, router: ClubNavigationRouter) {
        _viewModel = StateObject(
            wrappedValue: ClubMusiciansScreenViewModel(dependencies: dependencies, router: router)
        )
        self.uiFactory = dependencies.uiFactory
    }

    public var body: some View {
        let cellWidth = ClubMusiciansGridLayout.cellWidth
        VStack(spacing: 0) {
            AnyView(
                uiFactory.produce(
                    unit: .searchTextField($viewModel.searchText, prompt: "Имя или фамилия")
                )
            )
            .padding(.horizontal, ClubMusiciansGridLayout.screenEdgeInset)
            .padding(.top, 8)
            .padding(.bottom, 8)

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.fixed(cellWidth), spacing: ClubMusiciansGridLayout.columnSpacing),
                        GridItem(.fixed(cellWidth))
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.filteredMusicians) { musician in
                        Button {
                            viewModel.openMusicianDetail(musician)
                        } label: {
                            MusicianGridItemView(musician: musician, cellWidth: cellWidth)
                                .frame(width: cellWidth, height: MusicianGridItemLayout.cardHeight)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ClubMusiciansGridLayout.screenEdgeInset)
                .padding(.vertical, 12)
            }
            .appScrollContentBackgroundHidden()
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle("Музыканты")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Grid cell

private struct MusicianGridItemView: View {
    @ObservedObject var musician: MusicianViewModel
    let cellWidth: CGFloat

    private var imageSlotSize: CGSize {
        CGSize(width: cellWidth, height: MusicianGridItemLayout.imageSlotHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            photoSlot
                .frame(width: imageSlotSize.width, height: imageSlotSize.height)
                .clipped()

            infoBar
                .frame(width: cellWidth, height: MusicianGridItemLayout.infoBarHeight)
        }
        .frame(width: cellWidth, height: MusicianGridItemLayout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .onAppear { musician.loadImageIfNeeded() }
        .onDisappear { musician.cancelImageLoad() }
    }

    @ViewBuilder
    private var photoSlot: some View {
        let w = imageSlotSize.width
        let h = imageSlotSize.height
        Group {
            if let image = musician.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
            } else if musician.isLoadingImage {
                SkeletonView()
                    .frame(width: w, height: h)
            } else {
                ZStack {
                    Color(uiColor: Colors.cardBackground)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: w * 0.45, maxHeight: h * 0.45)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                }
                .frame(width: w, height: h)
            }
        }
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(musician.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(subtitleText)
                .font(.caption)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(uiColor: Colors.cardBackground))
    }

    private var subtitleText: String {
        let profession = musician.profession.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = musician.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? profession : description
    }
}
