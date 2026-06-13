//
//  MusicianAction.swift
//  SharedInfrastructure
//

import Foundation

public enum MusicianAction {
    case dismiss
    /// Переключить избранное по строковому id музыканта (`MusicianViewModel.id`).
    case favorite(String)
}

public typealias MusicianActionHandler = (MusicianAction) -> Void
