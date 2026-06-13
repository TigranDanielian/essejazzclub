//
//  ClubMenuScreen.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

private enum ClubMenuGridLayout {
    static let screenEdgeInset: CGFloat = 12
    static let columnSpacing: CGFloat = 12

    static var cellWidth: CGFloat {
        let totalWidth = UIScreen.screenWidth
        return (totalWidth - screenEdgeInset * 2 - columnSpacing) / 2
    }
}

private enum MenuGridItemLayout {
    static let cardHeight: CGFloat = 240
    static let infoBarHeight: CGFloat = 80
    static var imageSlotHeight: CGFloat { cardHeight - infoBarHeight }
}

private enum ClubMenuLayout {
    static let sectionSpacing: CGFloat = 28
}

private enum MenuCategoryChipID {
    static let all = "menu-category-all"

    static func category(_ name: String) -> String {
        "menu-category-\(name)"
    }
}

public struct ClubMenuScreen: View {
    @StateObject private var viewModel: ClubMenuScreenViewModel
    private let imageLoader: ImageLoader
    @State private var selectedItem: MenuItem?

    public init(dependencies: ClubMenuScreenDependencies) {
        _viewModel = StateObject(wrappedValue: ClubMenuScreenViewModel(dependencies: dependencies))
        self.imageLoader = dependencies.imageLoader
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.sections.isEmpty {
                ProgressView()
                    .tint(Color(uiColor: Colors.secondaryText))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.loadErrorMessage, viewModel.sections.isEmpty {
                menuEmptyState(
                    symbol: "exclamationmark.triangle",
                    title: "Не удалось загрузить",
                    subtitle: message
                )
            } else if viewModel.sections.isEmpty {
                menuEmptyState(
                    symbol: "fork.knife",
                    title: "Меню пусто",
                    subtitle: "Блюда появятся здесь, когда каталог будет доступен."
                )
            } else {
                menuContent
            }
        }
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle("Меню")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            ClubMenuItemDetailView(item: item, imageLoader: imageLoader)
        }
    }

    private var menuContent: some View {
        VStack(spacing: 0) {
            categoryFilterBar
                .background(Color(uiColor: Colors.mainBackground))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: ClubMenuLayout.sectionSpacing) {
                    ForEach(viewModel.visibleSections) { section in
                        menuSection(section)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
                .id(menuScrollContentID)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .appScrollContentBackgroundHidden()
        }
    }

    private var categoryFilterBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(
                        title: "Все",
                        isSelected: viewModel.selectedCategory == nil,
                        id: MenuCategoryChipID.all
                    ) {
                        viewModel.selectCategory(nil)
                        centerCategoryTab(MenuCategoryChipID.all, proxy: proxy)
                    }

                    ForEach(viewModel.categoryNames, id: \.self) { name in
                        let chipID = MenuCategoryChipID.category(name)
                        categoryChip(
                            title: name,
                            isSelected: viewModel.selectedCategory == name,
                            id: chipID
                        ) {
                            viewModel.selectCategory(name)
                            centerCategoryTab(chipID, proxy: proxy)
                        }
                    }
                }
                .padding(.horizontal, ClubMenuGridLayout.screenEdgeInset)
                .padding(.vertical, 10)
            }
        }
    }

    private var menuScrollContentID: String {
        viewModel.selectedCategory ?? MenuCategoryChipID.all
    }

    private func centerCategoryTab(_ id: String, proxy: ScrollViewProxy) {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private func categoryChip(
        title: String,
        isSelected: Bool,
        id: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(
                    isSelected
                        ? Color(uiColor: Colors.textInverted)
                        : Color(uiColor: Colors.text)
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? Color(uiColor: Colors.freetag)
                                : Color(uiColor: Colors.cardBackground)
                        )
                )
        }
        .buttonStyle(.plain)
        .id(id)
    }

    private func menuSection(_ section: MenuSection) -> some View {
        let cellWidth = ClubMenuGridLayout.cellWidth

        return VStack(alignment: .leading, spacing: 12) {
            if viewModel.selectedCategory == nil {
                Text(section.categoryName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .textCase(.uppercase)
                    .padding(.horizontal, ClubMenuGridLayout.screenEdgeInset)
            }

            LazyVGrid(
                columns: [
                    GridItem(.fixed(cellWidth), spacing: ClubMenuGridLayout.columnSpacing),
                    GridItem(.fixed(cellWidth)),
                ],
                spacing: 16
            ) {
                ForEach(section.items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        MenuItemCardView(
                            item: item,
                            imageLoader: imageLoader,
                            cellWidth: cellWidth
                        )
                        .frame(width: cellWidth, height: MenuGridItemLayout.cardHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ClubMenuGridLayout.screenEdgeInset)
        }
    }

    private func menuEmptyState(symbol: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Card

private struct MenuItemCardView: View {
    let item: MenuItem
    let imageLoader: ImageLoader
    let cellWidth: CGFloat

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    private var imageSlotSize: CGSize {
        CGSize(width: cellWidth, height: MenuGridItemLayout.imageSlotHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            photoSlot
                .frame(width: imageSlotSize.width, height: imageSlotSize.height)
                .clipped()

            infoBar
                .frame(width: cellWidth, height: MenuGridItemLayout.infoBarHeight)
        }
        .frame(width: cellWidth, height: MenuGridItemLayout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .task(id: item.id) {
            await loadImageIfNeeded()
        }
    }

    @ViewBuilder
    private var photoSlot: some View {
        let w = imageSlotSize.width
        let h = imageSlotSize.height
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
            } else if isLoadingImage {
                SkeletonView()
                    .frame(width: w, height: h)
            } else {
                ZStack {
                    Color(uiColor: Colors.cardBackground)
                    Image(systemName: "fork.knife")
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
            Text(item.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(item.formattedPrice)
                .font(.caption)
                .foregroundStyle(Color(uiColor: Colors.accentSheet))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(uiColor: Colors.cardBackground))
    }

    private func loadImageIfNeeded() async {
        guard image == nil else { return }
        guard let path = item.pictureURL, !path.isEmpty else { return }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let loaded = try? await imageLoader.loadImage(path: path) {
            image = loaded
        }
    }
}
