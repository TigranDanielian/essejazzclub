//
//  NavigationStackRouting.swift
//  SharedInfrastructure
//

import SwiftUI

/// Общий контракт для роутеров со стеком и модальными ветками.
@MainActor
public protocol Router: AnyObject, ObservableObject {
    associatedtype Route: Hashable & Identifiable
    func present(route: Route, presentation: NavigationPresentationStyle)
    func dismissPresentedOrPop()
}
extension Router {
    func present(route: Route, presentation: NavigationPresentationStyle = .push) {
        present(route: route, presentation: presentation)
    }
}

/// Универсальная реализация: `path` + опционально sheet / fullScreenCover.
@MainActor
open class StackNavigationRouter<Route: Hashable & Identifiable>: Router {
    @Published public var path: [Route] = []
    @Published public var sheetDestination: Route?
    @Published public var fullScreenDestination: Route?

    public init() {}

    /// Ключ для дедупликации push: при совпадении стек обрезается до существующего экрана.
    open func deduplicationKey(for route: Route) -> String {
        "\(route.id)"
    }

    public func present(route: Route, presentation: NavigationPresentationStyle) {
        switch presentation {
        case .push:
            let key = deduplicationKey(for: route)
            if let existingIndex = path.firstIndex(where: { deduplicationKey(for: $0) == key }) {
                path = Array(path.prefix(through: existingIndex))
            } else {
                path = path + [route]
            }
        case .sheet:
            sheetDestination = route
        case .fullScreenCover:
            fullScreenDestination = route
        }
    }

    /// Сначала закрывает модалку, иначе снимает верхний push.
    public func dismissPresentedOrPop() {
        if sheetDestination != nil {
            sheetDestination = nil
            return
        }
        if fullScreenDestination != nil {
            fullScreenDestination = nil
            return
        }
        pop()
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path = Array(path.dropLast())
    }
}
