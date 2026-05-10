//
//  EventAction.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Foundation

public enum EventNavigationAction {
    case onEventDetails(EventViewModel)
    case onMusicianDetails(MusicianViewModel)
    case dismiss
    case onBuy
}

public enum EventAction {
    case navigation(EventNavigationAction)
    case contextAction(EventContextButtonType)
}

public typealias EventActionHandler = (EventAction) -> Void

/// Разделяет чистую навигацию (`EventNavigationAction`) и побочные эффекты контекстных кнопок.
/// «Подробнее» в меню (`details`) открывает ту же карточку события, что и `onEventDetails`.
@MainActor
public func applyEventActionParts(
    _ action: EventAction,
    applyNavigation: (EventNavigationAction) -> Void,
    handleContextButton: (EventContextButtonType) -> Void
) {
    switch action {
    case .navigation(let nav):
        applyNavigation(nav)
    case .contextAction(let button):
        if case .details(let viewModel) = button {
            applyNavigation(.onEventDetails(viewModel))
        }
        handleContextButton(button)
    }
}
