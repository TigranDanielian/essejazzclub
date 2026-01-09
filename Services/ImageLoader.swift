//
//  ImageLoader.swift
//  Services
//
//  Created by Tigran Danielian on 01.06.2025.
//

import Foundation
import UIKit
import API

enum ImageLoaderError: LocalizedError {
    case invalidData
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        }
    }
}

public protocol ImageLoader: Sendable {
    func loadImage(path: String) async throws -> UIImage?
}

public final class ImageLoaderImpl: ImageLoader {
    private let host: URL

    public init(host: URL) {
        self.host = host
    }
    
    private let cache = ImageCache()
  
    public func loadImage(path: String) async throws -> UIImage? {
        guard let url = URL(string: path, relativeTo: host) else {
            print("❌ [Image Loader] invalid URL path \(path)")
            throw ImageLoaderError.invalidURL
        }
        if let cachedImage = await cache.image(for: path) {
            print("[Image Loader] using cached image for \(url)")
            return cachedImage
        }
       
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Проверяем HTTP статус код
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ [Image Loader] HTTP error with status code \(httpResponse.statusCode) for url \(url)")
                    throw ImageLoaderError.httpError(statusCode: httpResponse.statusCode)
                }
            }
            
            guard let image = await downsample(imageData: data, to: .init(width: 200, height: 200), scale: UIScreen.main.scale) else {
                print("❌ [Image Loader] failed to downsample image with url \(url)")
                throw ImageLoaderError.invalidData
            }
            
            await cache.insert(image, for: path)
            
            print("[Image Loader] loaded image for \(url)")
            
            return image
        } catch let error as ImageLoaderError {
            throw error
        } catch {
            // Обрабатываем сетевые ошибки (таймауты, отсутствие сети и т.д.)
            print("❌ [Image Loader] network error for url \(url): \(error.localizedDescription)")
            throw ImageLoaderError.networkError(error)
        }
    }
}


public actor ImageCache {
    private let cache = NSCache<NSString, UIImage>()

    public func image(for key: String) -> UIImage? {
        cache.object(forKey: key.asNSString)
    }

    public func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key.asNSString)
    }
}

extension String {
    var asNSString: NSString {
        NSString(string: self)
    }
}

private func downsample(imageData: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
        return nil
    }

    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale

    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ] as CFDictionary

    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
        return nil
    }

    return UIImage(cgImage: downsampledImage)
}

