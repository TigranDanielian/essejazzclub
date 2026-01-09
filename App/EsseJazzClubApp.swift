//
//  EsseJazzClubApp.swift
//  EsseJazzClub
//
//  Created by Tigran Danielian on 14.05.2025.
//

import SwiftUI
import Core
import Services
import HomeFeature
import ScheduleFeature
import ClubFeature
import API
import EventKit
import SharedInfrastructure

@main
struct EsseJazzClubApp: App {
    @StateObject private var appState = AppState()
    private let container = AppContainer(apiClient: DefaultApiClient(baseURL: Config.apiBaseUrl))
    
    init() {
        setupTabBarAppearance()
        setupNavBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.isReady {
                RootView(calendarCoordinator: container.calendarCoordinator)
                    .environmentObject(container)
            } else {
                LaunchView()
                    .environmentObject(container)
                    .environmentObject(appState)
            }
        }
    }
}

extension EsseJazzClubApp {
    private func setupNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.mainBackground // фон NavigationBar
        appearance.titleTextAttributes = [.foregroundColor: Colors.text] // цвет заголовка
        appearance.largeTitleTextAttributes = [.foregroundColor: Colors.text]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.mainBackground // ← Твой фон
        
        // Настройка цвета и шрифта иконок
        appearance.stackedLayoutAppearance.selected.iconColor = Colors.primary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: Colors.primary]
        
        appearance.stackedLayoutAppearance.normal.iconColor = Colors.secondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: Colors.secondaryText]
        
        let offset = UIOffset(horizontal: 0, vertical: 4)
                
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = offset
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = offset
        appearance.stackedItemPositioning = .automatic
        
        UITabBar.appearance().standardAppearance = appearance

        // Для iOS 15+
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct RootView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject var calendarCoordinator: EventCalendarCoordinator
    
    @State private var selectedEvent: EventViewModel? = nil
    @State private var selectedEventMusicians: [MusicianViewModel] = []
    
    var body: some View {
        TabView {
            HomeScreen(
                viewModel: HomeScreenViewModel(
                    eventsService: container.eventsService,
                    viewModelFactory: container.viewModelFactory,
                    favoritesStorage: container.favoritesStorage
                ),
                uiFactory: container.uiFactory,
                actionHandler: handleAction(_:)
            )
            .tabItem {
                Label("Главная", systemImage: "house")
            }
            
            ScheduleScreen(
                viewModel: ScheduleScreenViewModel(
                    eventsService: container.eventsService,
                    viewModelFactory: container.viewModelFactory
                ),
                uiFactory: container.uiFactory,
                actionHandler: handleAction
            )
            .tabItem {
                Label("Афиша", systemImage: "calendar")
            }
         
            ClubScreen()
                .tabItem {
                    Label("Клуб", systemImage: "music.note.house")
                }
        }
        .sheet(item: $selectedEvent, onDismiss: { selectedEvent = nil }) { event in
            NavigationView {
                AnyView(container.uiFactory.produce(unit: .eventDetails(event, handleAction(_:))))
            }
            .calendarActionHandler(coordinator: calendarCoordinator, isScuccess: $calendarCoordinator.showSuccessAlert, timeSelection: $calendarCoordinator.showTimeSelection)
        }
        .calendarActionHandler(coordinator: calendarCoordinator, isScuccess: $calendarCoordinator.showSuccessAlert, timeSelection: $calendarCoordinator.showTimeSelection)
    }
}

extension View {
    @discardableResult
    func calendarActionHandler(coordinator: EventCalendarCoordinator, isScuccess: Binding<Bool>, timeSelection: Binding<Bool>) -> some View {
        return self
            .alert("Event added", isPresented: isScuccess) {
                Button("OK") { }
            }
            .confirmationDialog("Select time", isPresented: timeSelection, titleVisibility: .visible, actions: {
                ForEach(coordinator.selectedCalendarEvent?.times ?? [], id: \.self) { item in
                    Button(item) {
                        coordinator.addEventToCalendar(event: coordinator.selectedCalendarEvent!, time: item)
                    }
                }
            })
    }
}

extension RootView {
    private func handleAction(_ action: EventAction) {
        switch action {
        case .contextAction(let contextAction):
            switch contextAction {
            case .calendar(let viewModel):
                container.calendarCoordinator.handleAction(with: viewModel)
            case .details(let viewModel):
                selectedEvent = viewModel
            case .favorite(let id):
                container.favoritesStorage.toggleState(forValue: id, forKey: .events)
            case .share:
                break
            }
        case .onSelect(let viewModel):
            selectedEvent = viewModel
            
        case .dismiss:
            selectedEvent = nil
            
        case .onBuy:
            break
        }
    }
}

final class AppState: ObservableObject {
    @Published var isReady = false
}

struct LaunchView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var appState: AppState
    
    @State private var alertInfo: AlertInfo?
    @State private var isAnimating = false // для анимации

    var body: some View {
        ShimmeringImage()
            .scaleEffect(isAnimating ? 2.0 : 1.0)  // увеличиваем
            .opacity(isAnimating ? 0 : 1)          // исчезаем
            .animation(.easeInOut(duration: 0.5), value: isAnimating)
        .onAppear {
            retryLoading()
        }
        .alert(item: $alertInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("Повторить"), action: {
                    retryLoading()
                })
            )
        }
    }
    
    @MainActor
    private func retryLoading() {
        container.loadEssentialData { result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isAnimating = true
                    // Через 1 секунду переключаем экран
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        appState.isReady = true
                    }
                }
            case .failure(let error):
                alertInfo = AlertInfo(title: "Ошибка", message: (error as? ApiError)?.localizedDescription ?? "Неизвестная ошибка")
            }
        }
    }
}

private struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ShimmeringImage: View {
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        Image(ImageResource.logoBlackEng)
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 40)
            .overlay(
                shimmer
                    .mask(Image(ImageResource.logoBlackEng).resizable().scaledToFit())
            )
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 2.0
                }
            }
    }

    var shimmer: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.6), Color.clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset * 300)
        .rotationEffect(.degrees(20))
    }
}
