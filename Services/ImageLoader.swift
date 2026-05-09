//
//  ImageLoader.swift
//  Services
//
//  Created by Tigran Danielian on 01.06.2025.
//

import Foundation
import UIKit
import API

/// Многие бэкенды отдают файлы только «браузерным» клиентам; голый URLSession часто получает 403 / HTML вместо картинки.
private let imageRequestUserAgent =
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

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

    /// Абсолютные URL из API — как есть; относительные — относительно `host`; `//host/path` — как https.
    private func resolvedURL(for path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//"), let url = URL(string: "https:\(trimmed)") {
            return url
        }
        if let direct = URL(string: trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))), direct.scheme != nil {
            return direct
        }
        let pathForRelative = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        guard let relative = URL(string: pathForRelative, relativeTo: host) else { return nil }
        return relative.absoluteURL
    }

    public func loadImage(path: String) async throws -> UIImage? {
        guard let url = resolvedURL(for: path) else {
            print("❌ [Image Loader] invalid URL path \(path)")
            throw ImageLoaderError.invalidURL
        }
        if let cachedImage = await cache.image(for: path) {
            print("[Image Loader] using cached image for \(url)")
            return cachedImage
        }

        do {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
            request.setValue(imageRequestUserAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            if url.host == host.host, let h = host.host {
                request.setValue("\(host.scheme ?? "http")://\(h)", forHTTPHeaderField: "Referer")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            // Проверяем HTTP статус код
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ [Image Loader] HTTP error with status code \(httpResponse.statusCode) for url \(url)")
                    throw ImageLoaderError.httpError(statusCode: httpResponse.statusCode)
                }
                let mime = httpResponse.mimeType ?? ""
                if mime.contains("text/html") {
                    print("❌ [Image Loader] server returned HTML (often 403/login page), url \(url)")
                }
            }

            let scale = await MainActor.run { UIScreen.main.scale }
            let image: UIImage
            if let downsampled = downsample(imageData: data, to: .init(width: 200, height: 200), scale: scale) {
                image = downsampled
            } else if let raw = UIImage(data: data) {
                image = raw
            } else {
                print("❌ [Image Loader] not a bitmap image (SVG/WebP-only?) or corrupt data, url \(url), \(data.count) bytes")
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

