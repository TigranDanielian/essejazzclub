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
    @State private var isHeaderHidden = false
    @State private var initialOffset: CGFloat?
    @State private var prevOffset: CGFloat?

    public init(
        viewModel: ScheduleScreenViewModel,
        uiFactory: any UIFactory
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
    }

    public var body: some View {
        ScrollView {
            GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geo.frame(in: .global).minY
                )
            }
            .frame(height: 1)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if initialOffset == nil {
                    initialOffset = value
                    return
                }
                
                let offset = value - (initialOffset ?? 0)
                let prev = prevOffset ?? 0
                
                // Hides search header while scrolling down, and shows when scrolling up
                
                if offset < 60, prev > offset, !isHeaderHidden {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHeaderHidden = true
                    }
                } else if prev < offset, isHeaderHidden {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHeaderHidden = false
                    }
                }
                
                prevOffset = offset
            }
            
            LazyVStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading, viewModel.grouped.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                } else if let emptyState = viewModel.listEmptyState {
                    if viewModel.isLoadingMore, viewModel.hasMore, viewModel.isQueryActive {
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
            .frame(minHeight: UIScreen.screenHeight - 120, alignment: .top)
        }
        .appScrollContentBackgroundHidden()
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            searchHeader
                .opacity(isHeaderHidden ? 0 : 1)
                .offset(y: isHeaderHidden ? -20 : 0)
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

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
