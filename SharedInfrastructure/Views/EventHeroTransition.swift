//
//  EventHeroTransition.swift
//  SharedInfrastructure
//

import SwiftUI

public enum EventHeroTransitionSourceID {
    public static func card(occurrenceIdentifier: String) -> String {
        "event-card-\(occurrenceIdentifier)"
    }

    public static func banner(occurrenceIdentifier: String) -> String {
        "event-banner-\(occurrenceIdentifier)"
    }
}

public struct EventHeroNamespaceKey: EnvironmentKey {
    public static let defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues {
    var eventHeroNamespace: Namespace.ID? {
        get { self[EventHeroNamespaceKey.self] }
        set { self[EventHeroNamespaceKey.self] = newValue }
    }
}

public extension View {
    func eventHeroTransitionSource(sourceID: String, isEnabled: Bool = true) -> some View {
        modifier(EventHeroTransitionSourceModifier(sourceID: sourceID, isEnabled: isEnabled))
    }

    func eventHeroNavigationTransition(sourceID: String?) -> some View {
        modifier(EventHeroNavigationTransitionModifier(sourceID: sourceID))
    }
}

private struct EventHeroTransitionSourceModifier: ViewModifier {
    let sourceID: String
    let isEnabled: Bool
    @Environment(\.eventHeroNamespace) private var namespace

    func body(content: Content) -> some View {
        if #available(iOS 18, *), let namespace, isEnabled {
            content.matchedTransitionSource(id: sourceID, in: namespace)
        } else {
            content
        }
    }
}

private struct EventHeroNavigationTransitionModifier: ViewModifier {
    let sourceID: String?
    @Environment(\.eventHeroNamespace) private var namespace

    func body(content: Content) -> some View {
        if #available(iOS 18, *), let namespace, let sourceID {
            content
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
                // Системный bar анимируется отдельно от zoom — при pop выглядит рассинхроном.
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
        }
    }
}
