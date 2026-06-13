//
//  RemoteImageLoadable.swift
//  SharedInfrastructure
//

import UIKit

@MainActor
public protocol RemoteImageLoadable: AnyObject {
    var image: UIImage? { get set }
    var isLoadingImage: Bool { get set }
    var imageLoadTask: Task<Void, Never>? { get set }
    var asyncImageLoader: AsyncImageLoader { get }
    var remoteImageURL: String? { get }
    var remoteImageFailurePlaceholder: UIImage? { get }

    func loadImageIfNeeded()
    func cancelImageLoad()
}

extension RemoteImageLoadable {
    public var remoteImageFailurePlaceholder: UIImage? { nil }

    public func loadImageIfNeeded() {
        guard image == nil, remoteImageURL != nil else { return }
        guard imageLoadTask == nil else { return }

        imageLoadTask = Task { [weak self] in
            await self?.loadRemoteImage()
        }
    }

    public func cancelImageLoad() {
        guard image == nil else { return }
        imageLoadTask?.cancel()
        imageLoadTask = nil
        isLoadingImage = false
    }

    private func loadRemoteImage() async {
        defer {
            imageLoadTask = nil
            if !Task.isCancelled {
                isLoadingImage = false
            }
        }

        guard !Task.isCancelled else { return }
        guard let remoteImageURL else { return }

        isLoadingImage = true
        do {
            let loadedImage = try await asyncImageLoader(remoteImageURL)
            guard !Task.isCancelled else { return }
            image = loadedImage
        } catch {
            guard !Task.isCancelled else { return }
            if let remoteImageFailurePlaceholder {
                image = remoteImageFailurePlaceholder
            }
        }
    }
}
