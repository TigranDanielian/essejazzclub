//
//  NavigationPresentationStyle.swift
//  SharedInfrastructure
//

import Foundation

/// Способ показа экрана поверх текущего контекста навигации.
public enum NavigationPresentationStyle: Hashable, Sendable {
    case push
    case sheet
    case fullScreenCover
}
