//
//  ClubShopScreen.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services

private enum ClubShopLayout {
    static let screenEdgeInset: CGFloat = 16
    static let sectionSpacing: CGFloat = 28
    static let cardSpacing: CGFloat = 12

    static var productCardWidth: CGFloat {
        min(UIScreen.screenWidth * 0.44, 180)
    }

    static let productCardHeight: CGFloat = 220
    static let imageSlotHeight: CGFloat = 140
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
                shopEmptyState(
                    symbol: "exclamationmark.triangle",
                    title: "Не удалось загрузить",
                    subtitle: message
                )
            } else if viewModel.sections.isEmpty {
                shopEmptyState(
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
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: ClubShopLayout.sectionSpacing) {
                ForEach(viewModel.sections) { section in
                    shopSection(section)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .appScrollContentBackgroundHidden()
    }

    private func shopSection(_ section: ShopSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.category.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .textCase(.uppercase)
                .padding(.horizontal, ClubShopLayout.screenEdgeInset)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: ClubShopLayout.cardSpacing) {
                    ForEach(section.products) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            ShopProductCardView(
                                product: product,
                                imageLoader: imageLoader,
                                cardWidth: ClubShopLayout.productCardWidth
                            )
                            .frame(
                                width: ClubShopLayout.productCardWidth,
                                height: ClubShopLayout.productCardHeight
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ClubShopLayout.screenEdgeInset)
            }
        }
    }

    private func shopEmptyState(symbol: String, title: String, subtitle: String) -> some View {
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

// MARK: - Product card

private struct ShopProductCardView: View {
    let product: ShopProduct
    let imageLoader: ImageLoader
    let cardWidth: CGFloat

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    private var displayName: String {
        ShopProductDisplay.name(for: product)
    }

    private var displayPrice: String? {
        ShopProductDisplay.price(for: product)
    }

    var body: some View {
        VStack(spacing: 0) {
            photoSlot
                .frame(width: cardWidth, height: ClubShopLayout.imageSlotHeight)
                .clipped()

            infoBar
                .frame(width: cardWidth, height: ClubShopLayout.productCardHeight - ClubShopLayout.imageSlotHeight)
        }
        .frame(width: cardWidth, height: ClubShopLayout.productCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .task(id: product.id) {
            await loadImageIfNeeded()
        }
    }

    @ViewBuilder
    private var photoSlot: some View {
        let w = cardWidth
        let h = ClubShopLayout.imageSlotHeight
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
            } else if isLoadingImage {
                ZStack {
                    Color(uiColor: Colors.cardBackground)
                    ProgressView()
                        .tint(Color(uiColor: Colors.secondaryText))
                }
            } else {
                ZStack {
                    Color(uiColor: Colors.cardBackground)
                    Image(systemName: "bag.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: w * 0.35, maxHeight: h * 0.35)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                }
            }
        }
        .frame(width: w, height: h)
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if let displayPrice {
                Text(displayPrice)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(uiColor: Colors.accentSheet))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(uiColor: Colors.cardBackground))
    }

    private func loadImageIfNeeded() async {
        guard image == nil else { return }
        guard let path = product.image?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else {
            return
        }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let loaded = try? await imageLoader.loadImage(path: path) {
            image = loaded
        }
    }
}
