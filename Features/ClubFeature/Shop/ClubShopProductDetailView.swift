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
        static let textHorizontalPadding: CGFloat = 12
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    DetailHeroImageView(
                        image: image,
                        isLoading: isLoadingImage,
                        placeholderSystemName: "bag.fill"
                    )

                    Text(displayName)
                        .bold()
                        .padding(.horizontal, Layout.textHorizontalPadding)
                        .padding(.top, 12)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(uiColor: Colors.text))

                    if let displayPrice {
                        Text(displayPrice)
                            .padding(.horizontal, Layout.textHorizontalPadding)
                            .font(.title3)
                            .foregroundStyle(Color(uiColor: Colors.accentSheet))
                    }

                    if !plainDescription.isEmpty || !attributedDescription.characters.isEmpty {
                        SeparatorView()

                        if !attributedDescription.characters.isEmpty {
                            ExpandableText(text: $attributedDescription, limit: 160)
                                .padding(12)
                                .foregroundStyle(Color(uiColor: Colors.text))
                        } else {
                            Text(plainDescription)
                                .padding(12)
                                .font(.caption2)
                                .foregroundStyle(Color(uiColor: Colors.text))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer()
                }
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
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }
        image = await PathImageLoading.load(imageLoader: imageLoader, path: product.image)
    }

    private func loadDescription() async {
        let raw = product.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return }
        guard let parsed = await HTMLBioFormatting.attributedString(from: raw) else { return }
        guard !Task.isCancelled else { return }
        attributedDescription = parsed
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
