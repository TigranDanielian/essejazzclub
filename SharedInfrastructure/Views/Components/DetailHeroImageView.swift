//
//  DetailHeroImageView.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

/// Фото в шапке детальных экранов (меню, шоп, музыкант): пропорции по картинке, без crop.
public struct DetailHeroImageView: View {
    let image: UIImage?
    let isLoading: Bool
    let placeholderSystemName: String

    public init(
        image: UIImage?,
        isLoading: Bool,
        placeholderSystemName: String = "photo"
    ) {
        self.image = image
        self.isLoading = isLoading
        self.placeholderSystemName = placeholderSystemName
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
                        Image(systemName: placeholderSystemName)
                            .font(.system(size: 48))
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    }
                }
            }

            if isLoading {
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
    }
}
