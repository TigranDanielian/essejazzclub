//
//  NavigationStackRouting.swift
//  SharedInfrastructure
//

import SwiftUI
import Combine

/// Общий контракт для роутеров со стеком и модальными ветками.
@MainActor
public protocol NavigationStackRouting: AnyObject, ObservableObject {
    func dismissPresentedOrPop()
    func synchronizeCaches()
}

/// Доступ к кэшам VM события / музыканта при сборке экранов деталей вне модуля-источника списка.
public protocol EventOccurrenceRoutingCaches: AnyObject {
    func cachedEventViewModel(forOccurrenceIdentifier: String) -> EventViewModel?
    func cachedMusicianViewModel(for musicianId: Int) -> MusicianViewModel?
}

/// Универсальная реализация: `path` + опционально sheet / fullScreenCover.
@MainActor
open class StackNavigationRouter<Route: Hashable & Identifiable>: NavigationStackRouting {
    @Published public var path: [Route] = []
    @Published public var sheetDestination: Route?
    @Published public var fullScreenDestination: Route?

    public init() {}

    public func present(_ destination: Route, presentation: NavigationPresentationStyle) {
        switch presentation {
        case .push:
            dismissModals()
            path.append(destination)
        case .sheet:
            dismissModals()
            sheetDestination = destination
        case .fullScreenCover:
            dismissModals()
            fullScreenDestination = destination
        }
        synchronizeCaches()
    }

    /// Сначала закрывает модалку, иначе снимает верхний push.
    public func dismissPresentedOrPop() {
        if sheetDestination != nil {
            sheetDestination = nil
            synchronizeCaches()
            return
        }
        if fullScreenDestination != nil {
            fullScreenDestination = nil
            synchronizeCaches()
            return
        }
        pop()
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
        synchronizeCaches()
    }

    public func popToRoot() {
        dismissModals()
        path.removeAll()
        synchronizeCaches()
    }

    private func dismissModals() {
        sheetDestination = nil
        fullScreenDestination = nil
    }

    public var modalRoutes: [Route] {
        [sheetDestination, fullScreenDestination].compactMap(\.self)
    }

    open func synchronizeCaches() {}
}
