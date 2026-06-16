//
//  ClubMenuScreen.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

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
                ClubCatalogEmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: "Не удалось загрузить",
                    subtitle: message
                )
            } else if viewModel.sections.isEmpty {
                ClubCatalogEmptyStateView(
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
                VStack(alignment: .leading, spacing: ClubCatalogGridLayout.sectionSpacing) {
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
                    ClubCatalogCategoryChip(
                        title: "Все",
                        isSelected: viewModel.selectedCategory == nil,
                        id: MenuCategoryChipID.all
                    ) {
                        viewModel.selectCategory(nil)
                        ClubCatalogCategoryTabs.center(MenuCategoryChipID.all, proxy: proxy)
                    }

                    ForEach(viewModel.categoryNames, id: \.self) { name in
                        let chipID = MenuCategoryChipID.category(name)
                        ClubCatalogCategoryChip(
                            title: name,
                            isSelected: viewModel.selectedCategory == name,
                            id: chipID
                        ) {
                            viewModel.selectCategory(name)
                            ClubCatalogCategoryTabs.center(chipID, proxy: proxy)
                        }
                    }
                }
                .padding(.horizontal, ClubCatalogGridLayout.screenEdgeInset)
                .padding(.vertical, 10)
            }
        }
    }

    private var menuScrollContentID: String {
        viewModel.selectedCategory ?? MenuCategoryChipID.all
    }

    private func menuSection(_ section: MenuSection) -> some View {
        let cellWidth = ClubCatalogGridLayout.cellWidth

        return VStack(alignment: .leading, spacing: 12) {
            if viewModel.selectedCategory == nil {
                Text(section.categoryName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .textCase(.uppercase)
                    .padding(.horizontal, ClubCatalogGridLayout.screenEdgeInset)
            }

            LazyVGrid(
                columns: [
                    GridItem(.fixed(cellWidth), spacing: ClubCatalogGridLayout.columnSpacing),
                    GridItem(.fixed(cellWidth)),
                ],
                spacing: 16
            ) {
                ForEach(section.items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        ClubCatalogGridCard(
                            title: item.name,
                            subtitle: item.formattedPrice,
                            imagePath: item.pictureURL,
                            placeholderSystemName: "fork.knife",
                            imageLoader: imageLoader,
                            cellWidth: cellWidth,
                            loadTaskID: item.id
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ClubCatalogGridLayout.screenEdgeInset)
        }
    }
}
