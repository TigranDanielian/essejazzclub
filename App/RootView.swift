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
                    actionHandler: handleHomeAction(_:)
                )
                .navigationDestination(for: HomeNavigationRouter.Route.self) { route in
                    homeRouteView(for: route)
                }
            }
            .sheet(item: $homeNavigationRouter.sheetDestination) { route in
                homeRouteView(for: route)
            }
            .fullScreenCover(item: $homeNavigationRouter.fullScreenDestination) { route in
                homeRouteView(for: route)
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
                    actionHandler: handleScheduleAction(_:),
                    onOpenFilter: { scheduleNavigationRouter.presentFilter(presentation: .sheet) }
                )
                .navigationDestination(for: ScheduleNavigationRouter.Route.self) { route in
                    scheduleRouteView(for: route)
                }
            }
            .sheet(item: $scheduleNavigationRouter.sheetDestination) { route in
                scheduleRouteView(for: route)
            }
            .fullScreenCover(item: $scheduleNavigationRouter.fullScreenDestination) { route in
                scheduleRouteView(for: route)
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
        case .eventDetail(let viewModel):
            eventDetailView(
                viewModel: viewModel,
                actionHandler: { eventActionHandler($0, navigation: { homeNavigationRouter.handle(.event(.navigation($0)), contextHandler: handleContextAction) })
                })
        case .musicianDetail(let viewModel):
            musicianDetailView(viewModel: viewModel, actionHandler: { _ in  homeNavigationRouter.dismissPresentedOrPop() })
        }
    }

    @ViewBuilder
    private func scheduleRouteView(for route: ScheduleNavigationRouter.Route) -> some View {
        switch route {
        case .eventDetail(let viewModel):
            eventDetailView(
                viewModel: viewModel,
                actionHandler: { eventActionHandler($0, navigation: { scheduleNavigationRouter.handle(.event(.navigation($0)), contextHandler: handleContextAction) })
                })
        case .musicianDetail(let viewModel):
            musicianDetailView(viewModel: viewModel, actionHandler: { _ in  scheduleNavigationRouter.dismissPresentedOrPop() })
        case .filter:
            scheduleFilterPlaceholder(dismiss: { scheduleNavigationRouter.dismissPresentedOrPop() })
        }
    }

    @ViewBuilder
    private func eventDetailView(viewModel: EventViewModel, actionHandler: @escaping EventActionHandler) -> some View {
        AnyView(container.uiFactory.produce(unit: .eventDetails(viewModel, actionHandler)))
    }

    @ViewBuilder
    private func musicianDetailView(viewModel: MusicianViewModel, actionHandler: @escaping MusicianActionHandler) -> some View {
        MusicianDetailsView(viewModel: viewModel, actionHandler: actionHandler)
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
    
    private func eventActionHandler(_ action: EventAction, navigation: @escaping (EventNavigationAction) -> Void) {
        switch action {
        case .navigation(let action):
            navigation(action)
        case .contextAction(let action):
            handleContextAction(action)
        }
    }
}
