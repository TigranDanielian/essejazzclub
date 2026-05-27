//
//  EsseJazzClubApp.swift
//  EsseJazzClub
//
//  Created by Tigran Danielian on 14.05.2025.
//

import SwiftUI
import Core
import Services
import API

@main
struct EsseJazzClubApp: App {
    @StateObject private var appState = AppState()
    private let container = AppContainer(apiClient: DefaultApiClient(baseURL: Config.apiBaseUrl))

    init() {
        AppTheme.applyInterfaceStyle()
        setupTabBarAppearance()
        setupNavBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isReady {
                    RootView()
                        .environmentObject(container)
                } else {
                    LaunchView()
                        .environmentObject(container)
                        .environmentObject(appState)
                }
            }
            .appPreferredColorScheme()
            .background(Color.appMainBackground)
        }
    }
}
