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

    init(screenModel: ClubScreenViewModel) {
        self.viewModel = screenModel
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
                                            ClubFavoriteConcertRowView(
                                                row: row,
                                                imageLoader: dependencies.imageLoader
                                            )
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
                                            ClubFavoriteMusicianRowView(
                                                row: row,
                                                imageLoader: dependencies.imageLoader
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
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

private struct ClubFavoriteConcertRowView: View {
    let row: ClubScreenViewModel.ConcertRow
    let imageLoader: ImageLoader

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipped()
                    .background(Color(uiColor: Colors.cardBackground))
                    .cornerRadius(10)

                if isLoadingImage {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: Colors.secondaryText).opacity(0.15))
                        .frame(width: 88, height: 88)
                }
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.title)
                    .font(.headline)
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .multilineTextAlignment(.leading)

                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    if row.dateChips.isEmpty {
                        Text("Нет дат в афише")
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(row.dateChips) { chip in
                                    Text(chip.label)
                                        .padding(2)
                                        .font(.caption)
                                        .foregroundStyle(Color(uiColor: Colors.text))
                                        .background(Color(uiColor: Colors.mainBackground))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .task(id: row.id) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let path = row.thumbnailUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else {
            return
        }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let loaded = try? await imageLoader.loadImage(path: path) {
            image = loaded
        }
    }
}

private struct ClubFavoriteMusicianRowView: View {
    let row: ClubScreenViewModel.MusicianRow
    let imageLoader: ImageLoader

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .background(
                    Circle()
                        .fill(Color(uiColor: Colors.cardBackground))
                )

                if isLoadingImage {
                    Circle()
                        .fill(Color(uiColor: Colors.secondaryText).opacity(0.15))
                        .frame(width: 72, height: 72)
                }
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.name)
                    .font(.headline)
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .multilineTextAlignment(.leading)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "music.mic")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    Text(row.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .task(id: row.id) {
            await loadAvatar()
        }
    }

    private func loadAvatar() async {
        guard let path = row.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty else {
            return
        }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let loaded = try? await imageLoader.loadImage(path: path) {
            image = loaded
        }
    }
}
