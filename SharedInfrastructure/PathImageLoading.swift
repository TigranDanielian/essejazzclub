//
//  PathImageLoading.swift
//  SharedInfrastructure
//

import UIKit
import Services

public enum PathImageLoading {
    public static func load(
        imageLoader: ImageLoader,
        path: String?,
        maxPixelSize: CGFloat? = 200
    ) async -> UIImage? {
        guard let path = path?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else {
            return nil
        }
        return try? await imageLoader.loadImage(path: path, maxPixelSize: maxPixelSize)
    }
}
