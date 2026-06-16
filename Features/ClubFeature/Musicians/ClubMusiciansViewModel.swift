//
//  ClubMusiciansViewModel.swift
//  ClubFeature
//
//  Created by Tigran Danielian on 16.05.2026.
//

import Foundation
import Services
import Core
import SharedInfrastructure
import Combine

// MARK: - View model

@MainActor
public final class ClubMusiciansScreenViewModel: ObservableObject {
    private let dependencies: ClubMusiciansScreenDependencies
    private let router: ClubNavigationRouter
    private var cancellables = Set<AnyCancellable>()

    @Published var searchText: String = ""
    @Published private(set) var allMusicians: [MusicianViewModel] = []

    var filteredMusicians: [MusicianViewModel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return allMusicians }
        let locale = Locale.current
        let needle = query.localizedLowercase.folding(locale: locale)
        return allMusicians.filter { Self.nameMatchesSearch($0.name, needle: needle, locale: locale) }
    }

    public init(dependencies: ClubMusiciansScreenDependencies, router: ClubNavigationRouter) {
        self.dependencies = dependencies
        self.router = router

        dependencies.musiciansService.state
            .receive(on: DispatchQueue.main)
            .map { [weak self] state -> [MusicianViewModel] in
                guard let self else { return [] }
                return state.musicians.map(self.makeMusicianViewModel)
            }
            .sink { [weak self] in self?.allMusicians = $0 }
            .store(in: &cancellables)
    }

    func openMusicianDetail(_ musician: MusicianViewModel) {
        router.present(route: .musicianDetail(musician), presentation: .push)
    }

    private func makeMusicianViewModel(_ musician: Musician) -> MusicianViewModel {
        guard let viewModel = dependencies.viewModelFactory.produce(
            unit: .musician(musician)
        ) as? MusicianViewModel else {
            return MusicianViewModel(
                model: musician,
                imageLoader: dependencies.imageLoader.loadImage(path:),
                favoritesStorage: dependencies.favoritesStorage
            )
        }
        return viewModel
    }

    /// Поиск по подстроке в полном имени или по любому из слов (имя / фамилия).
    private static func nameMatchesSearch(_ fullName: String, needle: String, locale: Locale) -> Bool {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let nameLower = trimmed.localizedLowercase.folding(locale: locale)
        if nameLower.contains(needle) { return true }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).map {
            String($0).localizedLowercase.folding(locale: locale)
        }
        return parts.contains { $0.contains(needle) }
    }
}
