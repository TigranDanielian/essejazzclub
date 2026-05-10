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
