//
//  ClubShopScreen.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

private enum ShopCategoryChipID {
    static let all = "shop-category-all"

    static func category(_ id: Int) -> String {
        "shop-category-\(id)"
    }
}

public struct ClubShopScreen: View {
    @StateObject private var viewModel: ClubShopScreenViewModel
    private let imageLoader: ImageLoader
    @State private var selectedProduct: ShopProduct?

    public init(dependencies: ClubShopScreenDependencies) {
        _viewModel = StateObject(
            wrappedValue: ClubShopScreenViewModel(dependencies: dependencies)
        )
        self.imageLoader = dependencies.imageLoader
    }

    public var body: some View {
        Group {
            if viewModel.isLoadingProducts && viewModel.sections.isEmpty {
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
                    symbol: "bag",
                    title: "Пока пусто",
                    subtitle: "Товары появятся здесь, когда каталог будет доступен."
                )
            } else {
                shopContent
            }
        }
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle("Гифт-шоп")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProduct) { product in
            ClubShopProductDetailView(product: product, imageLoader: imageLoader)
        }
    }

    private var shopContent: some View {
        VStack(spacing: 0) {
            categoryFilterBar
                .background(Color(uiColor: Colors.mainBackground))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: ClubCatalogGridLayout.sectionSpacing) {
                    ForEach(viewModel.visibleSections) { section in
                        shopSection(section)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
                .id(shopScrollContentID)
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
                        isSelected: viewModel.selectedCategoryID == nil,
                        id: ShopCategoryChipID.all
                    ) {
                        viewModel.selectCategory(id: nil)
                        ClubCatalogCategoryTabs.center(ShopCategoryChipID.all, proxy: proxy)
                    }

                    ForEach(viewModel.sections) { section in
                        let chipID = ShopCategoryChipID.category(section.category.id)
                        ClubCatalogCategoryChip(
                            title: section.category.name,
                            isSelected: viewModel.selectedCategoryID == section.category.id,
                            id: chipID
                        ) {
                            viewModel.selectCategory(id: section.category.id)
                            ClubCatalogCategoryTabs.center(chipID, proxy: proxy)
                        }
                    }
                }
                .padding(.horizontal, ClubCatalogGridLayout.screenEdgeInset)
                .padding(.vertical, 10)
            }
        }
    }

    private var shopScrollContentID: String {
        viewModel.selectedCategoryID.map(String.init) ?? ShopCategoryChipID.all
    }

    private func shopSection(_ section: ShopSection) -> some View {
        let cellWidth = ClubCatalogGridLayout.cellWidth

        return VStack(alignment: .leading, spacing: 12) {
            if viewModel.selectedCategoryID == nil {
                Text(section.category.name)
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
                ForEach(section.products) { product in
                    Button {
                        selectedProduct = product
                    } label: {
                        ClubCatalogGridCard(
                            title: ShopProductDisplay.name(for: product),
                            subtitle: ShopProductDisplay.price(for: product),
                            imagePath: product.image,
                            placeholderSystemName: "bag.fill",
                            imageLoader: imageLoader,
                            cellWidth: cellWidth,
                            loadTaskID: String(product.id)
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
