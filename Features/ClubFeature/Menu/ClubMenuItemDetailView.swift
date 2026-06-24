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
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    DetailHeroImageView(
                        image: image,
                        isLoading: isLoadingImage,
                        placeholderSystemName: "fork.knife"
                    )

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
            .ignoresSafeArea(edges: .top)
            .appScrollContentBackgroundHidden()
            .background(Color(uiColor: Colors.mainBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color(uiColor: Colors.text))
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task(id: item.id) {
            await loadImageIfNeeded()
            await loadDescription()
        }
    }

    private var plainDescription: String {
        let content = item.descriptionHTML?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.contains("<") else { return "" }
        return content
    }

    private func loadImageIfNeeded() async {
        guard image == nil else { return }
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }
        image = await PathImageLoading.load(imageLoader: imageLoader, path: item.pictureURL)
    }

    private func loadDescription() async {
        let raw = item.descriptionHTML?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return }
        guard let parsed = await HTMLBioFormatting.attributedString(from: raw) else { return }
        guard !Task.isCancelled else { return }
        attributedDescription = parsed
    }
}
