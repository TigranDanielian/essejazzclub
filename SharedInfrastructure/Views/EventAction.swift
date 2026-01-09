//
//  EventAction.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 08.07.2025.
//

import Foundation

public enum EventAction {
    case contextAction(EventContextButtonType)
    case onSelect(EventViewModel)
    case dismiss
    case onBuy
}

public typealias EventActionHandler = (EventAction) -> Void
