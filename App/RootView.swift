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

    var body: some View {
        TabView(selection: $appNavigationRouter.selectedTab) {
            NavigationStack(path: $homeNavigationRouter.path) {
                HomeScreen(
                    viewModel: HomeScreenViewModel(
                        eventsService: container.eventsService,
                        viewModelFactory: container.viewModelFactory,
                        favoritesStorage: container.favoritesStorage
                    ),
                    uiFactory: container.uiFactory,
                    actionHandler: homeHandleAction(_:)
                )
                .navigationDestination(for: HomeNavigationRouter.Route.self) { route in
                    homeRouteView(for: route)
                }
            }
            .sheet(item: $homeNavigationRouter.sheetDestination, onDismiss: {
                homeNavigationRouter.synchronizeCaches()
            }) { route in
                homeRouteView(for: route)
            }
            .fullScreenCover(item: $homeNavigationRouter.fullScreenDestination, onDismiss: {
                homeNavigationRouter.synchronizeCaches()
            }) { route in
                homeRouteView(for: route)
            }
            .onChange(of: homeNavigationRouter.path) { _, _ in
                homeNavigationRouter.synchronizeCaches()
            }
            .onChange(of: homeNavigationRouter.sheetDestination) { _, _ in
                homeNavigationRouter.synchronizeCaches()
            }
            .onChange(of: homeNavigationRouter.fullScreenDestination) { _, _ in
                homeNavigationRouter.synchronizeCaches()
            }
            .tabItem {
                Label("Главная", systemImage: "house")
            }
            .tag(AppTab.home)

            NavigationStack(path: $scheduleNavigationRouter.path) {
                ScheduleScreen(
                    viewModel: ScheduleScreenViewModel(
                        eventsService: container.eventsService,
                        viewModelFactory: container.viewModelFactory
                    ),
                    uiFactory: container.uiFactory,
                    actionHandler: scheduleHandleAction(_:),
                    onOpenFilter: { scheduleNavigationRouter.presentFilter(presentation: .sheet) }
                )
                .navigationDestination(for: ScheduleNavigationRouter.Route.self) { route in
                    scheduleRouteView(for: route)
                }
            }
            .sheet(item: $scheduleNavigationRouter.sheetDestination, onDismiss: {
                scheduleNavigationRouter.synchronizeCaches()
            }) { route in
                scheduleRouteView(for: route)
            }
            .fullScreenCover(item: $scheduleNavigationRouter.fullScreenDestination, onDismiss: {
                scheduleNavigationRouter.synchronizeCaches()
            }) { route in
                scheduleRouteView(for: route)
            }
            .onChange(of: scheduleNavigationRouter.path) { _, _ in
                scheduleNavigationRouter.synchronizeCaches()
            }
            .onChange(of: scheduleNavigationRouter.sheetDestination) { _, _ in
                scheduleNavigationRouter.synchronizeCaches()
            }
            .onChange(of: scheduleNavigationRouter.fullScreenDestination) { _, _ in
                scheduleNavigationRouter.synchronizeCaches()
            }
            .tabItem {
                Label("Афиша", systemImage: "calendar")
            }
            .tag(AppTab.schedule)

            ClubScreen()
                .tabItem {
                    Label("Клуб", systemImage: "music.note.house")
                }
                .tag(AppTab.club)
        }
    }

    @ViewBuilder
    private func homeRouteView(for route: HomeNavigationRouter.Route) -> some View {
        switch route {
        case .eventDetail(let occurrenceIdentifier):
            eventDetailView(occurrenceIdentifier: occurrenceIdentifier, caches: homeNavigationRouter, actionHandler: homeHandleAction(_:))
        case .musicianDetail(let musicianId):
            musicianDetailView(musicianId: musicianId, caches: homeNavigationRouter, dismiss: { homeNavigationRouter.dismissPresentedOrPop() })
        }
    }

    @ViewBuilder
    private func scheduleRouteView(for route: ScheduleNavigationRouter.Route) -> some View {
        switch route {
        case .eventDetail(let occurrenceIdentifier):
            eventDetailView(occurrenceIdentifier: occurrenceIdentifier, caches: scheduleNavigationRouter, actionHandler: scheduleHandleAction(_:))
        case .musicianDetail(let musicianId):
            musicianDetailView(musicianId: musicianId, caches: scheduleNavigationRouter, dismiss: { scheduleNavigationRouter.dismissPresentedOrPop() })
        case .filter:
            scheduleFilterPlaceholder(dismiss: { scheduleNavigationRouter.dismissPresentedOrPop() })
        }
    }

    @ViewBuilder
    private func eventDetailView(occurrenceIdentifier: String, caches: any EventOccurrenceRoutingCaches, actionHandler: @escaping EventActionHandler) -> some View {
        if let viewModel = resolveEventDetailViewModel(occurrenceIdentifier: occurrenceIdentifier, caches: caches) {
            AnyView(container.uiFactory.produce(unit: .eventDetails(viewModel, actionHandler)))
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func musicianDetailView(musicianId: Int, caches: any EventOccurrenceRoutingCaches, dismiss: @escaping () -> Void) -> some View {
        if let viewModel = resolveMusicianViewModel(musicianId: musicianId, caches: caches) {
            MusicianDetailsView(viewModel: viewModel, onDismiss: dismiss)
        } else {
            EmptyView()
        }
    }

    private func scheduleFilterPlaceholder(dismiss: @escaping () -> Void) -> some View {
        NavigationStack {
            Text("Фильтры")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: Colors.mainBackground))
                .navigationTitle("Фильтр")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть", action: dismiss)
                    }
                }
        }
    }
}
