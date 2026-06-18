//
//  EventBookingSlot.swift
//  SharedInfrastructure
//

import Foundation

public struct EventBookingSlot: Identifiable, Hashable {
    public let id: Int
    public let timeLabel: String
    public let url: URL

    public init(id: Int, timeLabel: String, url: URL) {
        self.id = id
        self.timeLabel = timeLabel
        self.url = url
    }
}
