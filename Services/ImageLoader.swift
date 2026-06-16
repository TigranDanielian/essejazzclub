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

private let defaultThumbnailMaxPixelSize: CGFloat = 200

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
    func loadImage(path: String, maxPixelSize: CGFloat?) async throws -> UIImage?
}

public extension ImageLoader {
    func loadImage(path: String) async throws -> UIImage? {
        try await loadImage(path: path, maxPixelSize: defaultThumbnailMaxPixelSize)
    }
}

public final class ImageLoaderImpl: ImageLoader {
    private let host: URL
    private let siteRoot: URL

    public init(host: URL, siteRoot: URL? = nil) {
        self.host = host
        self.siteRoot = siteRoot ?? URL(string: "https://www.jazzesse.ru")!
    }

    private let cache = ImageCache()

    /// Абсолютные URL — как есть; пути с `/` — от корня сайта; остальное — относительно `host`; `//host/path` — как https.
    func resolvedURL(for path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//"), let url = URL(string: "https:\(trimmed)") {
            return url
        }
        let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        if let direct = URL(string: cleaned), direct.scheme != nil {
            return direct
        }
        let base = cleaned.hasPrefix("/") ? siteRoot : host
        guard let relative = URL(string: cleaned, relativeTo: base) else { return nil }
        return relative.absoluteURL
    }

    public func loadImage(path: String, maxPixelSize: CGFloat?) async throws -> UIImage? {
        guard let url = resolvedURL(for: path) else {
            print("❌ [Image Loader] invalid URL path \(path)")
            throw ImageLoaderError.invalidURL
        }

        let cacheKey = Self.cacheKey(for: path, maxPixelSize: maxPixelSize)
        if let cachedImage = await cache.image(for: cacheKey) {
            print("[Image Loader] using cached image for \(url)")
            return cachedImage
        }

        do {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
            request.setValue(imageRequestUserAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            if isSameSite(url), let siteHost = siteRoot.host {
                request.setValue("\(siteRoot.scheme ?? "https")://\(siteHost)", forHTTPHeaderField: "Referer")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

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

            let image: UIImage
            if let maxPixelSize {
                let scale = await MainActor.run { UIScreen.main.scale }
                if let downsampled = downsample(imageData: data, maxPixelSize: maxPixelSize * scale) {
                    image = downsampled
                } else if let raw = UIImage(data: data) {
                    image = raw
                } else {
                    print("❌ [Image Loader] not a bitmap image (SVG/WebP-only?) or corrupt data, url \(url), \(data.count) bytes")
                    throw ImageLoaderError.invalidData
                }
            } else if let raw = UIImage(data: data) {
                image = raw
            } else {
                print("❌ [Image Loader] not a bitmap image (SVG/WebP-only?) or corrupt data, url \(url), \(data.count) bytes")
                throw ImageLoaderError.invalidData
            }

            await cache.insert(image, for: cacheKey)

            print("[Image Loader] loaded image for \(url)")

            return image
        } catch let error as ImageLoaderError {
            throw error
        } catch {
            print("❌ [Image Loader] network error for url \(url): \(error.localizedDescription)")
            throw ImageLoaderError.networkError(error)
        }
    }

    private func isSameSite(_ url: URL) -> Bool {
        guard let requestHost = Self.normalizedSiteHost(url.host) else { return false }
        return requestHost == Self.normalizedSiteHost(siteRoot.host)
    }

    private static func normalizedSiteHost(_ host: String?) -> String? {
        host?
            .lowercased()
            .replacingOccurrences(of: "www.", with: "")
    }

    private static func cacheKey(for path: String, maxPixelSize: CGFloat?) -> String {
        if let maxPixelSize {
            return "\(path)#thumb-\(Int(maxPixelSize))"
        }
        return "\(path)#full"
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

private func downsample(imageData: Data, maxPixelSize: CGFloat) -> UIImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
        return nil
    }

    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
    ] as CFDictionary

    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
        return nil
    }

    return UIImage(cgImage: downsampledImage)
}
