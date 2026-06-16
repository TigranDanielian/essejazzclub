//
//  ClubAboutScreen.swift
//  ClubFeature
//

import SwiftUI
import UIKit
import Core
import Services
import SharedInfrastructure
import Combine

/// Отдельный контейнер с `@StateObject`, чтобы `ClubAboutScreenViewModel` не создавался заново при каждом `body` роутера.
struct ClubAboutDestinationView: View {
    @StateObject private var viewModel: ClubAboutScreenViewModel
    private let imageLoader: ImageLoader

    init(contentService: ContentService, imageLoader: ImageLoader) {
        _viewModel = StateObject(wrappedValue: ClubAboutScreenViewModel(contentService: contentService))
        self.imageLoader = imageLoader
    }

    var body: some View {
        ClubAboutScreen(viewModel: viewModel, imageLoader: imageLoader)
            // Подписка не в `init` VM: первый запуск после появления экрана, вне синхронного прохода графа.
            .task { await viewModel.startObservingPages() }
    }
}

public struct ClubAboutScreen: View {
    @ObservedObject private var viewModel: ClubAboutScreenViewModel
    private let imageLoader: ImageLoader

    public init(viewModel: ClubAboutScreenViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.rows) { row in
                    switch row.kind {
                    case .text(let attributed):
                        Text(attributed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .image(let urlString):
                        clubAboutImage(urlString: urlString)
                    }
                }
            }
            .padding(16)
        }
        .appScrollContentBackgroundHidden()
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle("О клубе")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func clubAboutImage(urlString: String) -> some View {
        RemotePathImageView(path: urlString, imageLoader: imageLoader, maxPixelSize: nil)
    }
}

/// Строка для `ForEach`: готовый `AttributedString` или URL картинки (без вызова `htmlAttributed` из `body`).
public struct ClubAboutRow: Identifiable, Equatable {
    public let id: Int
    public let kind: ClubAboutRowKind
}

public enum ClubAboutRowKind: Equatable {
    case text(AttributedString)
    case image(url: String)
}

@MainActor
public final class ClubAboutScreenViewModel: ObservableObject {
    @Published public private(set) var rows: [ClubAboutRow] = []

    private let contentService: ContentService
    private var cancellables = Set<AnyCancellable>()
    private var observationStarted = false

    public init(contentService: ContentService) {
        self.contentService = contentService
    }

    /// Стартует подписку один раз; разбор HTML и `htmlAttributed` выполняются вне SwiftUI `body`.
    func startObservingPages() async {
        guard !observationStarted else { return }
        await Task.yield()

        contentService
            .pages()
            .receive(on: DispatchQueue.main)
            .map { pages -> [HTMLContentBlock] in
                guard let clubPage = pages.first(where: { $0.id == ContentPageId.club.rawValue }) else {
                    return []
                }
                return clubPage.text.htmlContentBlocks()
            }
            .sink { [weak self] blocks in
                guard let self else { return }
                Task { @MainActor in
                    await self.applyContentBlocks(blocks)
                }
            }
            .store(in: &cancellables)

        observationStarted = true
    }

    private func applyContentBlocks(_ blocks: [HTMLContentBlock]) async {
        var built: [ClubAboutRow] = []
        built.reserveCapacity(blocks.count)
        for (index, block) in blocks.enumerated() {
            switch block {
            case .text(let htmlFragment):
                let attributed = await HTMLBioFormatting.attributedString(from: htmlFragment)
                    ?? AttributedString(htmlFragment)
                built.append(ClubAboutRow(id: index, kind: .text(attributed)))
            case .image(let urlString):
                built.append(ClubAboutRow(id: index, kind: .image(url: urlString)))
            }
        }
        rows = built
    }
}
