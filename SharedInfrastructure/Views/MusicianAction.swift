//
//  MusicianAction.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 10.05.2026.
//

import Foundation

public enum MusicianAction {
    case dismiss
}

public typealias MusicianActionHandler = (MusicianAction) -> Void
