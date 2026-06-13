//
//  FavoriteMusicianRow.swift
//  SharedInfrastructure
//

import Foundation

/// Данные для плашки избранного музыканта (главная, клуб и т.д.).
public struct FavoriteMusicianRow: Identifiable, Hashable {
    public let id: String
    public let musicianId: Int
    public let name: String
    public let subtitle: String
    public let imageUrl: String?

    public init(id: String, musicianId: Int, name: String, subtitle: String, imageUrl: String?) {
        self.id = id
        self.musicianId = musicianId
        self.name = name
        self.subtitle = subtitle
        self.imageUrl = imageUrl
    }
}
