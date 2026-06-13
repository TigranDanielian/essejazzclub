//
//  EventViewModel.swift
//  ScheduleFeature
//
//  Created by Tigran Danielian on 10.06.2025.
//

import UIKit
import Services
import SwiftUI
import Combine
import Core

public typealias MusiciansProvider = (String) async throws -> AnyPublisher<[MusicianViewModel], Never>

public final class EventViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: EventViewModel, rhs: EventViewModel) -> Bool {
        lhs.occurrenceIdentifier == rhs.occurrenceIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(occurrenceIdentifier)
    }

    /// Идентификатор события для избранного и API (без слота даты).
    public let eventId: String
    /// Уникален для строки расписания (`ForEach`, навигация).
    public var id: String { occurrenceIdentifier }
    public var occurrenceIdentifier: String { eventOccurrenceIdentifier(for: model) }

    /// Вариант карточки: контекстное меню / дата — участвуют в UI, меняются при переиспользовании VM из фабрики.
    @Published public var hasContextMenu: Bool
    @Published public var hasDate: Bool

    @Published public var image: UIImage? = nil
    @Published public var isLoadingImage: Bool = false
    @Published public var dragOffset: CGFloat = 0
    @Published public var startDragOffset: CGFloat = 0
    @Published public var isFavorite: Bool = false
    @Published public var musicians: [MusicianViewModel] = []

    public var title: String
    public var description: String
    public var text: String
    public var times: [String]
    public var imageUrlString: String?
    public var isJazzLab: Bool
    public var date: Date
    public var isTop: Bool

    public var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")

        return formatter.string(from: date)
    }
    
    public func dateString(format: String = "d MMMM") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ru_RU")

        return formatter.string(from: date)
    }
    
    public var priceString: String? {
        prices.compactMap({ $0.price }).min().map {
            $0 > 0 ? "от \($0) ₽" : ""
        }
    }

    public var isFreeEvent: Bool {
        guard let minPrice = prices.map(\.price).min() else { return false }
        return minPrice == 0
    }

    public var bookingButtonTitle: String {
        isFreeEvent ? "Забронировать" : "Купить билет"
    }

    public var bookingURL: URL? {
        EventWebsiteLink.resolveBookingURL(from: model.bookLink)
    }

    public var apiEventId: Int { model.eventId }
    public var occurrenceSlotId: Int { model.dateWithTimes.id }
    public var websiteURL: URL {
        EventWebsiteLink.url(eventId: apiEventId, occurrenceId: occurrenceSlotId)
    }

    public var youTubeVideoIDs: [String] {
        model.youTubeLinks.compactMap { YouTubeVideoID.extract(from: $0) }
    }

    /// Дата и время начала каждого слота для календаря (таймзона Москва).
    public let calendarStartDates: [Date]
    
    @MainActor
    public lazy var favoriteButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(imagePublisher: contextButtonImagePublisher(for: .favorite(eventId)))
    
    @MainActor
    public lazy var shareButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(imagePublisher: contextButtonImagePublisher(for: .share(self)))
    
    @MainActor
    public let calendarButtonViewModel: EventContextButtonViewModel

    @MainActor
    public lazy var detailsButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(imagePublisher: contextButtonImagePublisher(for: .details(self)))

    private var prices: [Price]
    private let imageLoader: AsyncImageLoader
    private let favoritesStorage: FavoritesStorage<String>
    private let calendarEventsManager: CalendarEventsManager
    private var model: EventModel
    
    public var onSelect: (() -> Void)?

    @MainActor
    public init(
        model: EventModel,
        hasContextMenu: Bool,
        withDate: Bool = false,
        imageLoader: @escaping AsyncImageLoader,
        favoritesStorage: FavoritesStorage<String>,
        calendarEventsManager: CalendarEventsManager,
        musiciansProvider: MusiciansProvider?
    ) {
        self.model = model
        self.imageLoader = imageLoader
        self.favoritesStorage = favoritesStorage
        self.calendarEventsManager = calendarEventsManager
        self.hasContextMenu = hasContextMenu
        self.hasDate = withDate

        self.eventId = model.id
        self.isJazzLab = model.type == .jazzLab
        self.title = model.title
        self.description = model.description
        self.times = model.dateWithTimes.times.compactMap { $0.time.formatted(date: .omitted, time: .shortened) }
        self.date = model.dateWithTimes.date
        self.imageUrlString = model.thumbnailUrl
        self.prices = model.prices ?? []
        self.isTop = model.isTop
        self.text = model.text
        self.calendarStartDates = model.dateWithTimes.times.map {
            Self.calendarStartDate(day: model.dateWithTimes.date, time: $0.time)
        }

        let websiteURL = EventWebsiteLink.url(eventId: model.eventId, occurrenceId: model.dateWithTimes.id)
        self.calendarButtonViewModel = EventContextButtonViewModel(
            imagePublisher: Self.calendarImagePublisher(
                manager: calendarEventsManager,
                url: websiteURL,
                startDates: calendarStartDates,
                occurrenceIdentifier: eventOccurrenceIdentifier(for: model)
            )
        )

        Task {
            await loadImage()
        }

        Task {
            try await musiciansProvider?(model.id)
                .receive(on: DispatchQueue.main)
                .assign(to: &$musicians)
        }
        
    }
    
    func toggleOffset() {
        dragOffset = dragOffset == 0 ? -80 : 0
        startDragOffset = dragOffset
    }

    @MainActor
    private func loadImage() async {
        if let imageUrlString {
            isLoadingImage = true
            let loadedImage = try? await imageLoader(imageUrlString)
            self.image = loadedImage
            isLoadingImage = false
        }
    }

    func handleTap(type: EventContextButtonType) {
        switch type {
        case .favorite:
            favoritesStorage.toggleState(forValue: eventId, forKey: .events)
        case .calendar, .share, .details:
            break
        }
    }

    private static let moscowCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return calendar
    }()

    private static func calendarStartDate(day: Date, time: Date) -> Date {
        let parts = moscowCalendar.dateComponents([.hour, .minute], from: time)
        return moscowCalendar.date(
            bySettingHour: parts.hour ?? 20,
            minute: parts.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }
    
    private func contextButtonImagePublisher(for type: EventContextButtonType) -> AnyPublisher<UIImage?, Never> {
        switch type {
        case .favorite:
            favoritesStorage
                .isFavoritePublisher(for: eventId, key: .events)
                .map { isFavorite in
                    UIImage(systemName: isFavorite ? "heart.fill" : "heart")
                }
                .eraseToAnyPublisher()

        case .calendar:
            Self.calendarImagePublisher(
                manager: calendarEventsManager,
                url: websiteURL,
                startDates: calendarStartDates,
                occurrenceIdentifier: occurrenceIdentifier
            )

        default:
            Just(UIImage(systemName: type.imageName)).eraseToAnyPublisher()
        }
    }

    private static func calendarImagePublisher(
        manager: CalendarEventsManager,
        url: URL,
        startDates: [Date],
        occurrenceIdentifier: String
    ) -> AnyPublisher<UIImage?, Never> {
        let storeChanges = NotificationCenter.default.publisher(for: .EKEventStoreChanged).map { _ in () }
        let appChanges = NotificationCenter.default.publisher(for: .esseEventCalendarStateDidChange)
            .compactMap { $0.object as? String }
            .filter { $0 == occurrenceIdentifier }
            .map { _ in () }

        return Publishers.Merge(storeChanges, appChanges)
            .prepend(())
            .receive(on: DispatchQueue.main)
            .map { _ in
                let inCalendar = manager.isOccurrenceInCalendar(url: url, startDates: startDates)
                return UIImage(systemName: inCalendar ? "calendar.badge.checkmark" : "calendar")
            }
            .eraseToAnyPublisher()
    }
}
