//
//  AppNavigationRouter.swift
//  EsseJazzClub
//

import SwiftUI

/// Вкладки корневого `TabView` — единственная навигация верхнего уровня, общая для приложения.
enum AppTab: Hashable {
    case home
    case schedule
    case club
}

/// Координатор верхнего уровня: выбор вкладки и место для будущих глобальных сценариев (deep link, корневые модалки).
/// Экраны модулей ведут **модульные** роутеры (`HomeNavigationRouter`, `ScheduleNavigationRouter`).
@MainActor
final class AppNavigationRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
}
