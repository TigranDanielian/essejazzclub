//
//  EventActionHandlerEnvironment.swift
//  SharedInfrastructure
//

import SwiftUI

public struct EventActionHandlerKey: EnvironmentKey {
    public static let defaultValue: EventActionHandler? = nil
}

public extension EnvironmentValues {
    var eventActionHandler: EventActionHandler? {
        get { self[EventActionHandlerKey.self] }
        set { self[EventActionHandlerKey.self] = newValue }
    }
}
