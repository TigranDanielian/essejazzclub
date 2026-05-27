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
  public static var appMainBackground: Color { Color(uiColor: Colors.mainBackground) }
  public static var appCardBackground: Color { Color(uiColor: Colors.cardBackground) }
  public static var appText: Color { Color(uiColor: Colors.text) }
  public static var appSecondaryText: Color { Color(uiColor: Colors.secondaryText) }
}
