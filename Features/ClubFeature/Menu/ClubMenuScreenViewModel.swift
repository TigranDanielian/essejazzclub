//
//  ClubMenuScreenViewModel.swift
//  ClubFeature
//

import Combine
import Foundation
import Services

public struct ClubMenuScreenDependencies {
    public let contentService: ContentService
    public let imageLoader: ImageLoader

    public init(contentService: ContentService, imageLoader: ImageLoader) {
        self.contentService = contentService
        self.imageLoader = imageLoader
    }
}

@MainActor
public final class ClubMenuScreenViewModel: ObservableObject {
    private let dependencies: ClubMenuScreenDependencies
    private var loadCancellable: AnyCancellable?

    @Published private(set) var sections: [MenuSection] = []
    @Published private(set) var categoryNames: [String] = []
    @Published var selectedCategory: String?
    @Published private(set) var isLoading = false
    @Published private(set) var loadErrorMessage: String?

    public init(dependencies: ClubMenuScreenDependencies) {
        self.dependencies = dependencies
        loadMenu()
    }

    var visibleSections: [MenuSection] {
        guard let selectedCategory else { return sections }
        return sections.filter { $0.categoryName == selectedCategory }
    }

    func loadMenu() {
        loadCancellable?.cancel()
        isLoading = true
        loadErrorMessage = nil

        loadCancellable = dependencies.contentService.menu()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                isLoading = false
                if case .failure(let error) = completion {
                    loadErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] catalog in
                guard let self else { return }
                sections = catalog.sections
                categoryNames = catalog.categoryNames
                isLoading = false
                loadErrorMessage = nil
            }
    }

    func selectCategory(_ name: String?) {
        selectedCategory = name
    }
}
