//
//  MusicianModel.swift
//  Services
//
//  Created by Tigran Danielian on 26.05.2025.
//

import Foundation

import Foundation

public struct Musician: Decodable {
    public var id: Int
    public let name: String
    public let description: String
    public let text: String
    public let profession: String
    public let imageUrl: String?
//    let tags: String?
}

public struct EventMusician: Decodable {
    public var id: Int
    
    public let eventId: Int
    public let musicianId: Int
}
