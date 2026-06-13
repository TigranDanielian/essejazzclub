//
//  PaginatedEventScheduleRequest.swift
//  Services
//

import Foundation

/// Параметры `GET event-schedule` (сервер: `page` default 1, `per`/`perPage` default 20, max 100).
public struct PaginatedEventScheduleRequest {
    public static let defaultPage = 1
    public static let defaultPer = 20
    /// Размер страницы на вкладке «Афиша».
    public static let schedulePageSize = 10
    public static let maxPer = 100

    public let page: Int
    public let per: Int

    public init(page: Int = defaultPage, per: Int = defaultPer) {
        self.page = max(page, Self.defaultPage)
        self.per = min(max(per, 1), Self.maxPer)
    }
}
