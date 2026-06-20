//
//  AppTheme.swift
//  Core
//

import SwiftUI
import UIKit

public enum AppTheme {
  /// Единая тёмная тема для UIKit (навигация, таббар, системные контролы).
  @MainActor
  public static func applyInterfaceStyle() {
    UIView.appearance().overrideUserInterfaceStyle = .dark
    UIScrollView.appearance().backgroundColor = .clear
    UITableView.appearance().backgroundColor = Colors.mainBackground
  }
}

extension View {
  /// Убирает системный светлый фон у `ScrollView` / `List` (iOS 16+).
  @ViewBuilder
  public func appScrollContentBackgroundHidden() -> some View {
    scrollContentBackground(.hidden)
  }

  public func appPreferredColorScheme() -> some View {
    preferredColorScheme(.dark)
  }
}

extension Color {
  public static var appMainBackground: Color { Color(uiColor: Colors.background) }
  public static var appCardBackground: Color { Color(uiColor: Colors.surface) }
  public static var appText: Color { Color(uiColor: Colors.textPrimary) }
  public static var appSecondaryText: Color { Color(uiColor: Colors.textSecondary) }
  public static var appAccent: Color { Color(uiColor: Colors.accent) }
  public static var appSoftGold: Color { Color(uiColor: Colors.softGold) }
  public static var appFavorite: Color { Color(uiColor: Colors.favorite) }
  public static var appTopEvent: Color { Color(uiColor: Colors.topEvent) }
}
