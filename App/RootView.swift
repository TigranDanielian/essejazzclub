//
//  RootView.swift
//  EsseJazzClub
//

import SwiftUI
import Core
import Services
import HomeFeature
import ScheduleFeature
import ClubFeature
import SharedInfrastructure

struct RootView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject var appNavigationRouter = AppNavigationRouter()
    @StateObject var homeNavigationRouter = HomeNavigationRouter()
    @StateObject var scheduleNavigationRouter = ScheduleNavigationRouter()

    private var homeTabNavigation: HomeTabNavigating { homeNavigationRouter }
    private var scheduleTabNavigation: ScheduleTabNavigating { scheduleNavigationRouter }

    var body: some View {
        TabView(selection: $appNavigationRouter.selectedTab) {
            HomeTabRoot(
                router: homeNavigationRouter,
                handleContext: handleContextAction,
                routeView: { route in homeRouteView(for: route) }
            )
            .tabItem {
                Label("Главная", systemImage: "house")
            }
            .tag(AppTab.home)

            ScheduleTabRoot(
                router: scheduleNavigationRouter,
                handleContext: handleContextAction,
                routeView: { route in scheduleRouteView(for: route) }
            )
            .tabItem {
                Label("Афиша", systemImage: "calendar")
            }
            .tag(AppTab.schedule)

            ClubScreen(
                dependencies: ClubScreenDependencies(
                    eventsService: container.eventsService,
                    musiciansService: container.musiciansService,
                    contentService: container.contentService,
                    shopService: container.shopService,
                    favoritesStorage: container.favoritesStorage,
                    imageLoader: container.imageLoader,
                    viewModelFactory: container.viewModelFactory,
                    uiFactory: container.uiFactory,
                    calendarCoordinator: container.calendarCoordinator
                )
            )
            .tabItem {
                Label("Клуб", systemImage: "music.note.house")
            }
            .tag(AppTab.club)
        }
        .environmentObject(container)
    }

    @ViewBuilder
    private func homeRouteView(for route: HomeNavigationRouter.Route) -> some View {
        switch route {
        case .eventDetail(let viewModel, let heroTransitionSourceID):
            eventDetailView(
                viewModel: viewModel,
                heroTransitionSourceID: heroTransitionSourceID,
                actionHandler: homeTabNavigation.makeEventDetailActionHandler(contextHandler: handleContextAction)
            )
        case .musicianDetail(let viewModel):
            musicianDetailView(
                viewModel: viewModel,
                actionHandler: homeTabNavigation.makeMusicianDetailActionHandler(
                    favoritesStorage: container.favoritesStorage
                )
            )
        case .bookmarkedEventDetail(let occurrenceIdentifier, let mode):
            HomeFavoriteEventDetailHost(
                occurrenceIdentifier: occurrenceIdentifier,
                mode: mode,
                dependencies: HomeFavoriteEventDetailDependencies(
                    eventsService: container.eventsService,
                    favoritesStorage: container.favoritesStorage,
                    viewModelFactory: container.viewModelFactory,
                    uiFactory: container.uiFactory,
                    calendarCoordinator: container.calendarCoordinator
                ),
                router: homeNavigationRouter
            )
        }
    }

    @ViewBuilder
    private func scheduleRouteView(for route: ScheduleNavigationRouter.Route) -> some View {
        switch route {
        case .eventDetail(let viewModel, let heroTransitionSourceID):
            eventDetailView(
                viewModel: viewModel,
                heroTransitionSourceID: heroTransitionSourceID,
                actionHandler: scheduleTabNavigation.makeEventDetailActionHandler(contextHandler: handleContextAction)
            )
        case .musicianDetail(let viewModel):
            musicianDetailView(
                viewModel: viewModel,
                actionHandler: scheduleTabNavigation.makeMusicianDetailActionHandler(
                    favoritesStorage: container.favoritesStorage
                )
            )
        case .filter:
            EmptyView()
        }
    }

    @ViewBuilder
    private func eventDetailView(
        viewModel: EventViewModel,
        heroTransitionSourceID: String?,
        actionHandler: @escaping EventActionHandler
    ) -> some View {
        AnyView(container.uiFactory.produce(
            unit: .eventDetails(viewModel, actionHandler, nil, .default, heroTransitionSourceID: heroTransitionSourceID, onSelectUpcomingOccurrence: nil)
        ))
    }

    @ViewBuilder
    private func musicianDetailView(viewModel: MusicianViewModel, actionHandler: @escaping MusicianActionHandler) -> some View {
        MusicianDetailsView(viewModel: viewModel, actionHandler: actionHandler)
    }
}

// MARK: - Вкладки: VM через `@StateObject` во вложенном view, куда `AppContainer` передаётся из `body`

private struct HomeTabRoot<RouteContent: View>: View {
    @EnvironmentObject private var container: AppContainer
    @ObservedObject var router: HomeNavigationRouter
    let handleContext: (EventContextButtonType) -> Void
    @ViewBuilder let routeView: (HomeNavigationRouter.Route) -> RouteContent

    init(
        router: HomeNavigationRouter,
        handleContext: @escaping (EventContextButtonType) -> Void,
        @ViewBuilder routeView: @escaping (HomeNavigationRouter.Route) -> RouteContent
    ) {
        self.router = router
        self.handleContext = handleContext
        self.routeView = routeView
    }

    var body: some View {
        HomeTabShell(
            container: container,
            router: router,
            handleContext: handleContext,
            routeView: routeView
        )
    }
}

private struct HomeTabShell<RouteContent: View>: View {
    let container: AppContainer
    @ObservedObject var router: HomeNavigationRouter
    let handleContext: (EventContextButtonType) -> Void
    @ViewBuilder let routeView: (HomeNavigationRouter.Route) -> RouteContent

    @StateObject private var viewModel: HomeScreenViewModel
    @State private var navPath: [HomeNavigationRouter.Route] = []
    @State private var heroBannerHiddenForNavigation = false
    @State private var heroBannerHideTask: Task<Void, Never>?
    @Namespace private var eventHeroNamespace

    init(
        container: AppContainer,
        router: HomeNavigationRouter,
        handleContext: @escaping (EventContextButtonType) -> Void,
        @ViewBuilder routeView: @escaping (HomeNavigationRouter.Route) -> RouteContent
    ) {
        self.container = container
        self.router = router
        self.handleContext = handleContext
        self.routeView = routeView
        _viewModel = StateObject(
            wrappedValue: HomeScreenViewModel(
                eventsService: container.eventsService,
                musiciansService: container.musiciansService,
                viewModelFactory: container.viewModelFactory,
                favoritesStorage: container.favoritesStorage,
                tabNavigation: router,
                contextHandler: handleContext
            )
        )
    }

    private var showsHeroBanner: Bool {
        viewModel.hasHeroBanner && !heroBannerHiddenForNavigation
    }

    private var isHeroBannerPlaybackActive: Bool {
        viewModel.hasHeroBanner && navPath.isEmpty
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            HomeHeroShell(
                hasBanner: viewModel.hasHeroBanner,
                showsBanner: showsHeroBanner,
                isBannerPlaybackActive: isHeroBannerPlaybackActive,
                bannerEvents: viewModel.mainEvents,
                imageLoader: container.imageLoader,
                onBannerEventDetails: { event in
                    viewModel.onEventDetails(
                        event,
                        heroTransitionSourceID: EventHeroTransitionSourceID.banner(
                            occurrenceIdentifier: event.occurrenceIdentifier
                        )
                    )
                }
            ) {
                HomeScreen(
                    viewModel: viewModel,
                    uiFactory: container.uiFactory
                )
                .navigationDestination(for: HomeNavigationRouter.Route.self) { route in
                    routeView(route)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .environment(\.eventHeroNamespace, eventHeroNamespace)
        .onAppear {
            navPath = router.path
            container.calendarEventsManager.requestAccessIfNeeded()
        }
        .onChange(of: router.path) { _, newPath in
            guard newPath != navPath else { return }
            navPath = newPath
        }
        .onChange(of: navPath.isEmpty) { _, isEmpty in
            heroBannerHideTask?.cancel()
            heroBannerHideTask = nil

            if isEmpty {
                heroBannerHiddenForNavigation = false
            } else {
                heroBannerHideTask = Task { @MainActor in
                    // Держим баннер видимым на время zoom-перехода (iOS 18), затем прячем под деталкой.
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled, !navPath.isEmpty else { return }
                    heroBannerHiddenForNavigation = true
                }
            }
        }
        .onChange(of: navPath) { _, newPath in
            guard newPath != router.path else { return }
            router.path = newPath
        }
        .sheet(item: $router.sheetDestination) { route in
            routeView(route)
        }
        .fullScreenCover(item: $router.fullScreenDestination) { route in
            routeView(route)
        }
    }
}

private struct ScheduleTabRoot<RouteContent: View>: View {
    @EnvironmentObject private var container: AppContainer
    @ObservedObject var router: ScheduleNavigationRouter
    let handleContext: (EventContextButtonType) -> Void
    @ViewBuilder let routeView: (ScheduleNavigationRouter.Route) -> RouteContent

    init(
        router: ScheduleNavigationRouter,
        handleContext: @escaping (EventContextButtonType) -> Void,
        @ViewBuilder routeView: @escaping (ScheduleNavigationRouter.Route) -> RouteContent
    ) {
        self.router = router
        self.handleContext = handleContext
        self.routeView = routeView
    }

    var body: some View {
        ScheduleTabShell(
            container: container,
            router: router,
            handleContext: handleContext,
            routeView: routeView
        )
    }
}

private struct ScheduleTabShell<RouteContent: View>: View {
    let container: AppContainer
    @ObservedObject var router: ScheduleNavigationRouter
    let handleContext: (EventContextButtonType) -> Void
    @ViewBuilder let routeView: (ScheduleNavigationRouter.Route) -> RouteContent

    @StateObject private var viewModel: ScheduleScreenViewModel
    @Namespace private var eventHeroNamespace

    init(
        container: AppContainer,
        router: ScheduleNavigationRouter,
        handleContext: @escaping (EventContextButtonType) -> Void,
        @ViewBuilder routeView: @escaping (ScheduleNavigationRouter.Route) -> RouteContent
    ) {
        self.container = container
        self.router = router
        self.handleContext = handleContext
        self.routeView = routeView
        _viewModel = StateObject(
            wrappedValue: ScheduleScreenViewModel(
                eventsService: container.eventsService,
                viewModelFactory: container.viewModelFactory,
                tabNavigation: router,
                contextHandler: handleContext
            )
        )
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            ScheduleScreen(viewModel: viewModel, uiFactory: container.uiFactory)
                .navigationDestination(for: ScheduleNavigationRouter.Route.self) { route in
                    routeView(route)
                }
        }
        .environment(\.eventHeroNamespace, eventHeroNamespace)
        .sheet(item: $router.sheetDestination) { route in
            switch route {
            case .filter:
                ScheduleFilterScreen(
                    viewModel: ScheduleFilterViewModel(
                        appliedFilter: viewModel.filter,
                        onApply: { viewModel.updateFilter($0) }
                    ),
                    onDismiss: { router.dismissPresentedOrPop() }
                )
            default:
                routeView(route)
            }
        }
        .fullScreenCover(item: $router.fullScreenDestination) { route in
            routeView(route)
        }
    }
}
