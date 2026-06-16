//
//  RemotePathImageView.swift
//  SharedInfrastructure
//

import SwiftUI
import Core
import Services

public struct RemotePathImageView: View {
    let path: String
    let imageLoader: ImageLoader
    let cornerRadius: CGFloat
    let maxPixelSize: CGFloat?

    @State private var image: UIImage?
    @State private var isLoadingImage = true

    public init(
        path: String,
        imageLoader: ImageLoader,
        cornerRadius: CGFloat = 12,
        maxPixelSize: CGFloat? = 200
    ) {
        self.path = path
        self.imageLoader = imageLoader
        self.cornerRadius = cornerRadius
        self.maxPixelSize = maxPixelSize
    }

    public var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(cornerRadius)
            } else if isLoadingImage {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                EmptyView()
            }
        }
        .task(id: taskID) {
            image = nil
            isLoadingImage = true
            await loadImageIfNeeded()
        }
    }

    private var taskID: String {
        if let maxPixelSize {
            return "\(path)#\(Int(maxPixelSize))"
        }
        return "\(path)#full"
    }

    private func loadImageIfNeeded() async {
        defer { isLoadingImage = false }
        guard !Task.isCancelled else { return }
        image = await PathImageLoading.load(
            imageLoader: imageLoader,
            path: path,
            maxPixelSize: maxPixelSize
        )
    }
}
