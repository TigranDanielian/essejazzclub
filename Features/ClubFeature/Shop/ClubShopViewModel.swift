//
//  ClubShopViewModel.swift
//  ClubFeature
//

import Combine
import Foundation
import Services

// MARK: - Section model

public struct ShopSection: Identifiable, Equatable {
    public let category: ShopCategory
    public let products: [ShopProduct]

    public var id: Int { category.id }
}

// MARK: - Dependencies

public struct ClubShopScreenDependencies {
    public let shopService: ShopService
    public let imageLoader: ImageLoader

    public init(shopService: ShopService, imageLoader: ImageLoader) {
        self.shopService = shopService
        self.imageLoader = imageLoader
    }
}

// MARK: - View model

@MainActor
public final class ClubShopScreenViewModel: ObservableObject {
    private let dependencies: ClubShopScreenDependencies
    private var cancellables = Set<AnyCancellable>()
    private var productsCancellable: AnyCancellable?

    @Published private(set) var sections: [ShopSection] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var loadErrorMessage: String?

    public init(dependencies: ClubShopScreenDependencies) {
        self.dependencies = dependencies

        dependencies.shopService.categories()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                self?.reloadProducts(for: categories.filter { $0.id != 4 })
            }
            .store(in: &cancellables)
    }

    private func reloadProducts(for categories: [ShopCategory]) {
        productsCancellable?.cancel()

        guard !categories.isEmpty else {
            sections = []
            isLoadingProducts = false
            return
        }

        isLoadingProducts = true
        loadErrorMessage = nil

        productsCancellable = dependencies.shopService.products(categoryId: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                isLoadingProducts = false
                if case .failure(let error) = completion {
                    loadErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] products in
                guard let self else { return }
                sections = Self.makeSections(categories: categories, products: products)
                isLoadingProducts = false
                loadErrorMessage = nil
            }
    }

    private static func makeSections(
        categories: [ShopCategory],
        products: [ShopProduct]
    ) -> [ShopSection] {
        let grouped = Dictionary(grouping: products, by: \.categoryId)
        return categories.compactMap { category in
            guard let items = grouped[category.id], !items.isEmpty else { return nil }
            return ShopSection(category: category, products: items)
        }
    }
}
