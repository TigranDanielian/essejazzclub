//
//  ClubShopProductDetailView.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

struct ClubShopProductDetailView: View {
    let product: ShopProduct
    let imageLoader: ImageLoader

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var isLoadingImage = false
    @State private var attributedDescription: AttributedString = .init()

    private enum Layout {
        static let photoHeight: CGFloat = 280
        static let horizontalPadding: CGFloat = 16
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoBlock
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.photoHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text(displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(uiColor: Colors.text))

                    if let displayPrice {
                        Text(displayPrice)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color(uiColor: Colors.accentSheet))
                    }

                    if !plainDescription.isEmpty || !attributedDescription.characters.isEmpty {
                        shopDescriptionSeparator()

                        if !attributedDescription.characters.isEmpty {
                            ExpandableText(text: $attributedDescription, limit: 160)
                                .foregroundStyle(Color(uiColor: Colors.text))
                        } else {
                            Text(plainDescription)
                                .font(.body)
                                .foregroundStyle(Color(uiColor: Colors.text))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, 12)
            }
            .appScrollContentBackgroundHidden()
            .background(Color(uiColor: Colors.mainBackground))
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                        .foregroundStyle(Color(uiColor: Colors.primary))
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task(id: product.id) {
            await loadImageIfNeeded()
            await loadDescription()
        }
    }

    private func shopDescriptionSeparator() -> some View {
        Rectangle()
            .frame(height: 5)
            .cornerRadius(5)
            .foregroundStyle(Color(uiColor: Colors.separator))
    }

    @ViewBuilder
    private var photoBlock: some View {
        ZStack {
            if let image {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            } else {
                Color(uiColor: Colors.cardBackground)
                Image(systemName: "bag.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
            }

            if isLoadingImage {
                SkeletonView()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var displayName: String {
        ShopProductDisplay.name(for: product)
    }

    private var displayPrice: String? {
        ShopProductDisplay.price(for: product)
    }

    private var plainDescription: String {
        ShopProductDisplay.plainContent(for: product)
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

    private func loadDescription() async {
        let raw = product.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return }

        let font = UIFont.systemFont(ofSize: 16, weight: .regular)
        let parsed = await Task.detached(priority: .userInitiated) {
            raw.htmlAttributed(font: font, color: Colors.text)
        }.value

        guard !Task.isCancelled else { return }
        if let parsed {
            attributedDescription = parsed
        }
    }
}

// MARK: - Display helpers

enum ShopProductDisplay {
    static func name(for product: ShopProduct) -> String {
        let name = product.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Товар" : name
    }

    static func price(for product: ShopProduct) -> String? {
        guard let price = product.price?.trimmingCharacters(in: .whitespacesAndNewlines), !price.isEmpty else {
            return nil
        }
        return price
    }

    static func plainContent(for product: ShopProduct) -> String {
        let content = product.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard content.contains("<") == false else { return "" }
        return content
    }
}
