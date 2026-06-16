//
//  FavoriteEventDetailMode.swift
//  SharedInfrastructure
//

import Foundation

/// Режим деталки избранного концерта: обзор по событию или конкретный слот.
public enum FavoriteEventDetailMode: String, Hashable {
    case overview
    case slot
}
