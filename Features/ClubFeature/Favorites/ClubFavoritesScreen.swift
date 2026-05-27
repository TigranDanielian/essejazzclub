//
//  ClubFavoritesScreen.swift
//  ClubFeature
//

import SwiftUI
import Services
import Core
import SharedInfrastructure

struct ClubFavoritesScreen: View {
    @ObservedObject private var viewModel: ClubScreenViewModel

    private var dependencies: ClubScreenDependencies { viewModel.dependencies }

    /// `nil` — оба блока; иначе только выбранный тип.
    @State private var activeFilter: [FavoritesSegment] = []

    init(viewModel: ClubScreenViewModel) {
        self.viewModel = viewModel
    }

    private var isCompletelyEmpty: Bool {
        viewModel.concertRows.isEmpty && viewModel.musicianRows.isEmpty
    }

    private var hasConcerts: Bool { !viewModel.concertRows.isEmpty }
    private var hasMusicians: Bool { !viewModel.musicianRows.isEmpty }

    /// Панель фильтра нужна только когда оба списка непусты.
    private var showsFilterBar: Bool { hasConcerts && hasMusicians }

    private var showsConcertsSection: Bool {
        hasConcerts && (activeFilter.isEmpty || activeFilter.contains(.concerts))
    }

    private var showsMusiciansSection: Bool {
        hasMusicians && (activeFilter.isEmpty || activeFilter.contains(.musicians))
    }

    var body: some View {
        Group {
            if isCompletelyEmpty {
                emptyState
            } else {

                VStack(spacing: 0) {
                    if showsFilterBar {
                        HStack(spacing: 10) {
                            filterChip(title: "Концерты", segment: .concerts)
                            filterChip(title: "Музыканты", segment: .musicians)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 22) {
                            if showsConcertsSection {
                                favoritesSectionHeader("Концерты")
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.concertRows) { row in
                                        Button {
                                            viewModel.presentRoute(
                                                .favoriteEventDetail(
                                                    occurrenceIdentifier: row.primaryOccurrenceIdentifier,
                                                    mode: .overview
                                                ),
                                                presentation: .push
                                            )
                                        } label: {
                                            AnyView(dependencies.uiFactory.produce(unit: .favoriteConcertRow(row)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            if showsMusiciansSection {
                                favoritesSectionHeader("Музыканты")
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.musicianRows) { row in
                                        Button {
                                            openMusicianDetail(row: row)
                                        } label: {
                                            AnyView(dependencies.uiFactory.produce(unit: .favoriteMusicianRow(row)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .appScrollContentBackgroundHidden()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle("Избранное")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func filterChip(title: String, segment: FavoritesSegment) -> some View {
        let isSelected = activeFilter.contains(segment)
        return Button {
            if activeFilter.contains(segment) {
                activeFilter.removeAll { $0 == segment }
            } else {
                activeFilter.append(segment)
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(uiColor: isSelected ? Colors.textInverted : Colors.text))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(uiColor: isSelected ? Colors.primary : Colors.cardBackground))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func favoritesSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color(uiColor: Colors.secondaryText))
            .textCase(.uppercase)
    }

    private func openMusicianDetail(row: ClubScreenViewModel.MusicianRow) {
        let musician = viewModel.musicianFromCatalog(id: row.musicianId)
            ?? Musician(
                id: row.musicianId,
                name: row.name,
                description: "",
                text: "",
                profession: row.subtitle,
                imageUrl: row.imageUrl
            )
        guard let vm = dependencies.viewModelFactory.produce(unit: .musician(musician)) as? MusicianViewModel else { return }
        viewModel.presentRoute(.musicianDetail(vm), presentation: .push)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart")
                .font(.system(size: 44))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
            Text("Пока пусто")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.text))
            Text("Добавляйте в избранное концерты и музыкантов — с главной, из афиши или с карточки музыканта.")
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum FavoritesSegment: Equatable {
    case concerts
    case musicians
}
