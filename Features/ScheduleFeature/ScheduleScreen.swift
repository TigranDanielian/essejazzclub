//
//  ScheduleScreen.swift
//  API
//
//  Created by Tigran Danielian on 30.05.2025.
//

import SwiftUI
import Core
import SharedInfrastructure

private enum ScheduleScreenLayout {
    static let searchHeaderHeight: CGFloat = 52
}

public struct ScheduleScreen: View {
    private var uiFactory: any UIFactory
    /// Родитель (`ScheduleTabShell`) держит VM в `@StateObject` — здесь только наблюдение.
    @ObservedObject var viewModel: ScheduleScreenViewModel

    public init(
        viewModel: ScheduleScreenViewModel,
        uiFactory: any UIFactory
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading, viewModel.grouped.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                } else if let emptyState = viewModel.listEmptyState {
                    if viewModel.isLoadingMore, viewModel.hasMore, viewModel.isFilterActive || viewModel.isSearchActive {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                    } else {
                        ScheduleEmptyStateView(state: emptyState)
                    }

                    if viewModel.showPaginationFooter {
                        paginationFooter
                            .id(viewModel.loadGeneration)
                    }
                } else {
                    ForEach(viewModel.grouped) { day in
                        ScheduleDayView(
                            eventsDay: day,
                            actionHandler: { viewModel.handleAction(.event($0)) }
                        )
                    }

                    if viewModel.showPaginationFooter {
                        paginationFooter
                            .id(viewModel.loadGeneration)
                    }
                }
            }
            .padding(.top, 20)
            .frame(minHeight: UIScreen.screenHeight - 120)
        }
        .appScrollContentBackgroundHidden()
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            searchHeader
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadInitialIfNeeded()
        }
        .background(Color(uiColor: Colors.mainBackground))
    }

    private var searchHeader: some View {
        HStack(spacing: 8) {
            AnyView(
                uiFactory.produce(
                    unit: .searchTextField(
                        searchBinding,
                        prompt: "Название мероприятия",
                        onClear: { viewModel.clearSearchInput() }
                    )
                )
            )

            Button {
                viewModel.openFilter()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: UIImage(resource: .filter).withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Color(uiColor: viewModel.isFilterActive ? Colors.accentSheet : Colors.secondaryText))
                }
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: ScheduleScreenLayout.searchHeaderHeight)
        .background(Color(uiColor: Colors.mainBackground))
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { viewModel.searchInputText },
            set: { viewModel.setSearchInput($0) }
        )
    }

    private var paginationFooter: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingMore {
                ProgressView()
            }
            Spacer()
        }
        .frame(height: 44)
        .onAppear {
            Task { await viewModel.loadMore() }
        }
    }
}
