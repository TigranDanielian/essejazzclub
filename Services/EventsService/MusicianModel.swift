//
//  MusicianModel.swift
//  Services
//
//  Created by Tigran Danielian on 26.05.2025.
//

import Foundation

public struct Musician: Decodable {
    public var id: Int
    public let name: String
    public let description: String
    public let text: String
    public let profession: String
    public let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, text, profession, imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        text = try container.decode(String.self, forKey: .text)
        profession = try container.decode(String.self, forKey: .profession)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    }

    public init(id: Int, name: String, description: String, text: String, profession: String, imageUrl: String?) {
        self.id = id
        self.name = name
        self.description = description
        self.text = text
        self.profession = profession
        self.imageUrl = imageUrl
    }
}

public struct EventMusician: Decodable {
    public var id: Int
    
    public let eventId: Int
    public let musicianId: Int
}
