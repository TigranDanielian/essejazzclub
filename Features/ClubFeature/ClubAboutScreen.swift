//
//  ClubAboutScreen.swift
//  ClubFeature
//

import SwiftUI
import UIKit
import Core
import Services
import Combine

/// Отдельный контейнер с `@StateObject`, чтобы `ClubAboutScreenViewModel` не создавался заново при каждом `body` роутера.
struct ClubAboutDestinationView: View {
    @StateObject private var viewModel: ClubAboutScreenViewModel

    init(contentService: ContentService) {
        _viewModel = StateObject(wrappedValue: ClubAboutScreenViewModel(contentService: contentService))
    }

    var body: some View {
        ClubAboutScreen(viewModel: viewModel)
            // Подписка не в `init` VM: первый запуск после появления экрана, вне синхронного прохода графа.
            .task { await viewModel.startObservingPages() }
    }
}

public struct ClubAboutScreen: View {
    @ObservedObject private var viewModel: ClubAboutScreenViewModel

    public init(viewModel: ClubAboutScreenViewModel) {
        self.viewModel = viewModel
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
        if let url = Self.resolveImageURL(urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                case .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Text(urlString)
                .font(.caption2)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
        }
    }

    /// Абсолютный URL, либо корень сайта для путей вида `/upload/...`.
    private static func resolveImageURL(_ raw: String) -> URL? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        if let u = URL(string: t), u.scheme != nil { return u }
        if t.hasPrefix("//") { return URL(string: "https:" + t) }
        if t.hasPrefix("/") { return URL(string: "https://www.jazzesse.ru\(t)") }
        return URL(string: t)
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
                    await Task.yield()
                    self.applyContentBlocks(blocks)
                }
            }
            .store(in: &cancellables)

        observationStarted = true
    }

    private func applyContentBlocks(_ blocks: [HTMLContentBlock]) {
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        var built: [ClubAboutRow] = []
        built.reserveCapacity(blocks.count)
        for (index, block) in blocks.enumerated() {
            switch block {
            case .text(let htmlFragment):
                let attributed = htmlFragment.htmlAttributed(font: font, color: Colors.text)
                    ?? AttributedString(htmlFragment)
                built.append(ClubAboutRow(id: index, kind: .text(attributed)))
            case .image(let urlString):
                built.append(ClubAboutRow(id: index, kind: .image(url: urlString)))
            }
        }
        rows = built
    }
}
