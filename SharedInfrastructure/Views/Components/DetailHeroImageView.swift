//
//  DetailHeroImageView.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

public enum DetailHeroImageLayout: Sendable {
    /// Карточка с закруглением (меню, шоп).
    case insetCard
    /// На всю ширину до верхнего края (деталка музыканта).
    case edgeToTop
}

/// Фото в шапке детальных экранов (меню, шоп, музыкант): пропорции по картинке, без crop.
public struct DetailHeroImageView: View {
    let image: UIImage?
    let isLoading: Bool
    let placeholderSystemName: String
    let layout: DetailHeroImageLayout

    public init(
        image: UIImage?,
        isLoading: Bool,
        placeholderSystemName: String = "photo",
        layout: DetailHeroImageLayout = .insetCard
    ) {
        self.image = image
        self.isLoading = isLoading
        self.placeholderSystemName = placeholderSystemName
        self.layout = layout
    }

    private enum Layout {
        static let placeholderAspectRatio: CGFloat = 9 / 16
    }

    private var photoHeight: CGFloat {
        guard let image, image.size.width > 0 else {
            return UIScreen.screenWidth * Layout.placeholderAspectRatio
        }
        return UIScreen.screenWidth * image.size.height / image.size.width
    }

    public var body: some View {
        let content = ZStack {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                } else {
                    ZStack {
                        Color(uiColor: Colors.cardBackground)
                        Image(systemName: placeholderSystemName)
                            .font(.system(size: 48))
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    }
                }
            }

            if isLoading {
                SkeletonView()
                    .cornerRadius(layout == .insetCard ? 12 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: photoHeight)

        switch layout {
        case .insetCard:
            content
                .shadow(radius: 12)
                .cornerRadius(12)
                .clipped()
                .ignoresSafeArea(.container, edges: .horizontal)
        case .edgeToTop:
            content
                .clipped()
                .ignoresSafeArea(.container, edges: [.horizontal, .top])
        }
    }
}
