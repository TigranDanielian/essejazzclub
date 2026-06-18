//
//  EventModel.swift
//  Services
//
//  Created by Tigran Danielian on 26.05.2025.
//

import Foundation

public struct EventModel {
    public var id: String
    public var title: String
    public var description: String
    public var text: String
    public var dateWithTimes: DateWithTimes
    public var thumbnailUrl: String?
    public var bannerUrl: String?
    public var type: EventType
    public var prices: [Price]?
    public var isTop: Bool
    public var youTubeLinks: [String]
    public var eventId: Int
    public var bookLink: String?

    public init(id: String, title: String, description: String, text: String, dateWithTimes: DateWithTimes, thumbnailUrl: String?, bannerUrl: String?, type: Services.EventType, prices: [Price]?, isTop: Bool, youTubeLinks: [String], eventId: Int, bookLink: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.text = text
        self.dateWithTimes = dateWithTimes
        self.thumbnailUrl = thumbnailUrl
        self.bannerUrl = bannerUrl
        self.type = type
        self.prices = prices
        self.isTop = isTop
        self.youTubeLinks = youTubeLinks
        self.eventId = eventId
        self.bookLink = bookLink
    }
}

public struct DateWithTimes {
    public let id: Int
    public let date: Date
    public let times: [Time]
    
    public init(id: Int, date: Date, times: [Time]) {
        self.id = id
        self.date = date
        self.times = times
    }
}

public enum EventType: String {
    case main = "Главная сцена"
    case jazzLab = "Jazz Lab"
}

public enum PaymentZone: String {
    case main = "Основной зал"
    case small = "Малый зал"
    case jazzLab = "Jazz Lab"
}

public struct Time {
    public let id: Int
    public let time: Date
    public let bookLink: String?

    public init(id: Int, time: Date, bookLink: String? = nil) {
        self.id = id
        self.time = time
        self.bookLink = bookLink
    }
}

public struct RemoteEvent: Decodable {
    
    let id: Int
    let title: String?
    let text: String
    let description: String
    let image: String?
    let thumbnail: String?
    
    private let slider: Int?
    private let video: String?
    
    var inTop: Bool {
        slider == 1 ? true : false
    }
    
    var youTubeLinks: [String] {
        video?.base64Decoded()?.extractLinks() ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case text
        case description
        case image
        case thumbnail
        case video
        case slider
    }
}

public struct RemoteEventDate: Decodable {
    let id: Int
    let eventId: Int
    let date: Date
    let time: Date
    let bookLink: String?

    private let _prices: String // db gives an encoded and serialized array as string
    private let jazzlab: Int?
    
    var isJazzLab: Bool {
        Bool(truncating: NSNumber.init(integerLiteral: (jazzlab ?? 0)))
    }
    
    var prices: [Price]? {
        getPricesArray(from: _prices.base64Decoded()?.removingPercentEncoding ?? "")
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case date
        case time
        case _prices = "prices"
        case jazzlab
        case bookLink
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.eventId = try container.decode(Int.self, forKey: .eventId)
        self._prices = try container.decode(String.self, forKey: ._prices)
        self.jazzlab = try container.decodeIfPresent(Int.self, forKey: .jazzlab)
        self.bookLink = try container.decodeIfPresent(String.self, forKey: .bookLink)

        let dateString = try container.decode(String.self, forKey: .date)
        let timeString = try container.decode(String.self, forKey: .time)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        guard let parsedDate = isoFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid ISO 8601 date")
        }
        self.date = parsedDate

        // Время в формате "HH:mm"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        
        if let parsedTime = timeFormatter.date(from: timeString) {
            self.time = parsedTime
        } else {
            throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Invalid time format")
        }
    }
}

func getPricesArray(from string: String) -> [Price] {
    let array = string.replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .split(separator: ";")
    
    guard !array.isEmpty else {
        return []
    }
    
    var prices: [Int] = []
    var zonesString: [String] = []
    
    for (index, item) in array.enumerated() {
        if item.contains("price") {
            if let price = Int(array[index + 1].split(separator: ":").last ?? "") {
                prices.append(price)
            }
        }
        
        if item.contains("zona") && !item.contains("zona_en") {
            var zone = String(array[index + 1].split(separator: ":").last ?? "")
            zone.removeAll(where: { !$0.isLetter && !$0.isWhitespace })
            
            zonesString.append(zone)
        }
    }
    
    guard prices.count == zonesString.count else {
        return []
    }
    
    return prices
        .enumerated()
        .map({
            Price(
                id: $0.offset,
                zone: zonesString[$0.offset],
                price: $0.element
            )
        })
}

public struct Price: Codable, Identifiable {
    public let id: Int
    public let zone: String
    public let price: Int
    
    enum CodingKeys: String, CodingKey {
        case zone = "zona"
        case price
        case id
    }
   
    init(
        id: Price.ID,
        zone: String,
        price: Int
    ) {
        self.id = id
        self.zone = zone
        self.price = price
        
    }
}


extension String {
    func extractLinks() -> [String] {
        let pattern = #"https?://[^\s"'<>]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return legacyExtractLinks()
        }
        let range = NSRange(startIndex..., in: self)
        let matches = regex.matches(in: self, range: range)
        let links = matches.compactMap { match -> String? in
            guard let linkRange = Range(match.range, in: self) else { return nil }
            return String(self[linkRange])
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'<>"))
        }
        return links.isEmpty ? legacyExtractLinks() : links
    }

    private func legacyExtractLinks() -> [String] {
        split(separator: "\"")
            .map(String.init)
            .map { $0.replacingOccurrences(of: " ", with: "") }
            .filter { $0.contains("http") }
    }
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
