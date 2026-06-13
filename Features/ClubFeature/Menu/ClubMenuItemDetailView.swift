//
//  ClubMenuItemDetailView.swift
//  ClubFeature
//

import SwiftUI
import Core
import Services
import SharedInfrastructure

struct ClubMenuItemDetailView: View {
    let item: MenuItem
    let imageLoader: ImageLoader

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var isLoadingImage = false
    @State private var attributedDescription: AttributedString = .init()

    private enum Layout {
        static let textHorizontalPadding: CGFloat = 12
        static let placeholderAspectRatio: CGFloat = 9 / 16
    }

    private var photoHeight: CGFloat {
        guard let image, image.size.width > 0 else {
            return UIScreen.screenWidth * Layout.placeholderAspectRatio
        }
        return UIScreen.screenWidth * image.size.height / image.size.width
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        Group {
                            if let image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            } else {
                                ZStack {
                                    Color(uiColor: Colors.cardBackground)
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 48))
                                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                                }
                            }
                        }

                        if isLoadingImage {
                            SkeletonView()
                                .cornerRadius(12)
                        }
                    }
                    .shadow(radius: 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: photoHeight)
                    .cornerRadius(12)
                    .clipped()
                    .ignoresSafeArea(.container, edges: .horizontal)

                    Text(item.name)
                        .bold()
                        .padding(.horizontal, Layout.textHorizontalPadding)
                        .padding(.top, 12)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(uiColor: Colors.text))

                    Text(item.formattedPrice)
                        .padding(.horizontal, Layout.textHorizontalPadding)
                        .font(.title3)
                        .foregroundStyle(Color(uiColor: Colors.accentSheet))

                    if !plainDescription.isEmpty || !attributedDescription.characters.isEmpty {
                        menuDescriptionSeparator()

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
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                        .foregroundStyle(Color(uiColor: Colors.primary))
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task(id: item.id) {
            await loadImageIfNeeded()
            await loadDescription()
        }
    }

    private func menuDescriptionSeparator() -> some View {
        Rectangle()
            .frame(height: 5)
            .cornerRadius(5)
            .foregroundStyle(Color(uiColor: Colors.separator))
            .padding(.horizontal, 20)
    }

    private var plainDescription: String {
        let content = item.descriptionHTML?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.contains("<") else { return "" }
        return content
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

    private func loadDescription() async {
        let raw = item.descriptionHTML?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return }

        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let parsed = await Task.detached(priority: .userInitiated) {
            raw.htmlAttributed(font: font, color: Colors.text)
        }.value

        guard !Task.isCancelled else { return }
        if let parsed {
            attributedDescription = parsed
        }
    }
}
