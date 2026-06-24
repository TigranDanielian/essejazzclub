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
        case .eventDetail(let viewModel):
            eventDetailView(
                viewModel: viewModel,
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
        case .eventDetail(let viewModel):
            eventDetailView(
                viewModel: viewModel,
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
    private func eventDetailView(viewModel: EventViewModel, actionHandler: @escaping EventActionHandler) -> some View {
        AnyView(container.uiFactory.produce(unit: .eventDetails(viewModel, actionHandler, nil, .default, onSelectUpcomingOccurrence: nil)))
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
        viewModel.hasHeroBanner && navPath.isEmpty
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: viewModel.hasHeroBanner ? -HomeHeroSheetLayout.sheetOverlap : 0) {
                if viewModel.hasHeroBanner {
                    HomeHeroBanner(
                        events: viewModel.mainEvents,
                        imageLoader: container.imageLoader,
                        isPlaybackActive: showsHeroBanner,
                        onDetails: { viewModel.onEventDetails($0) }
                    )
                    .opacity(showsHeroBanner ? 1 : 0)
                    .allowsHitTesting(showsHeroBanner)
                    .accessibilityHidden(!showsHeroBanner)
                }

                HomeScreen(
                    viewModel: viewModel,
                    uiFactory: container.uiFactory
                )
                .padding(.top, viewModel.hasHeroBanner ? -HomeHeroSheetLayout.scrollHitExtensionHeight : 0)
                .zIndex(1)
                .navigationDestination(for: HomeNavigationRouter.Route.self) { route in
                    routeView(route)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .top)
            .background(Color(uiColor: Colors.mainBackground))
        }
        .onAppear {
            navPath = router.path
            container.calendarEventsManager.requestAccessIfNeeded()
        }
        .onChange(of: router.path) { _, newPath in
            guard newPath != navPath else { return }
            navPath = newPath
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
