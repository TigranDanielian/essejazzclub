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

@MainActor
public final class EventViewModel: ObservableObject {
    /// Идентификатор события для избранного и API (без слота даты).
    public nonisolated let eventId: String
    /// Уникален для строки расписания (`ForEach`, навигация).
    public nonisolated let occurrenceIdentifier: String

    /// Вариант карточки: контекстное меню / дата — задаётся при создании через фабрику.
    public let hasContextMenu: Bool
    public let hasDate: Bool
    public let hasPrice: Bool

    @Published public var image: UIImage? = nil
    @Published public var isLoadingImage: Bool = false
    @Published public var musicians: [MusicianViewModel] = []

    public var title: String { presentation.title }
    public var description: String { presentation.description }
    public var text: String { presentation.text }
    public var times: [String] { presentation.times }
    public var imageUrlString: String? { presentation.imageUrlString }
    public var bannerUrlString: String? { presentation.bannerUrlString }
    public var isJazzLab: Bool { presentation.isJazzLab }
    public var date: Date { presentation.date }
    public var isTop: Bool { presentation.isTop }
    public var dateString: String { presentation.dateString }

    public func dateString(format: String) -> String {
        presentation.dateString(format: format)
    }

    public var priceString: String? { presentation.priceString }
    public var isFreeEvent: Bool { presentation.isFreeEvent }
    public var bookingButtonTitle: String { presentation.bookingButtonTitle }

    public var bookingSlots: [EventBookingSlot] { presentation.bookingSlots }

    public var bookingURL: URL? {
        bookingSlots.first?.url
    }

    public var occurrenceSlotId: Int { model.dateWithTimes.id }
    public var websiteURL: URL {
        EventWebsiteLink.url(eventId: model.eventId, occurrenceId: occurrenceSlotId)
    }

    public var youTubeVideoIDs: [String] {
        model.youTubeLinks.compactMap { YouTubeVideoID.extract(from: $0) }
    }

    public var calendarStartDates: [Date] { presentation.calendarStartDates }

    public lazy var favoriteHeartButtonViewModel: FavoriteHeartButtonViewModel = FavoriteHeartButtonViewModel(
        favoritesStorage: favoritesStorage,
        value: eventId,
        key: .events
    )

    public lazy var shareButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(
        imagePublisher: EventContextButtonPublishers.staticIcon(named: EventContextButtonType.share(self).imageName)
    )

    public lazy var calendarButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(
        imagePublisher: EventContextButtonPublishers.calendar(
            manager: calendarEventsManager,
            url: websiteURL,
            startDates: calendarStartDates,
            occurrenceIdentifier: occurrenceIdentifier
        )
    )

    public lazy var calendarToggleViewModel: EventCalendarToggleViewModel = EventCalendarToggleViewModel(
        manager: calendarEventsManager,
        url: websiteURL,
        startDates: calendarStartDates,
        occurrenceIdentifier: occurrenceIdentifier
    )

    public lazy var detailsButtonViewModel: EventContextButtonViewModel = EventContextButtonViewModel(
        imagePublisher: EventContextButtonPublishers.staticIcon(named: EventContextButtonType.details(self).imageName)
    )

    private var model: EventModel
    private var presentation: EventPresentation { EventPresentation(model: model) }
    private let imageLoader: AsyncImageLoader
    private let favoritesStorage: FavoritesStorage<String>
    private let calendarEventsManager: CalendarEventsManager
    private let musiciansProvider: MusiciansProvider?
    public var imageLoadTask: Task<Void, Never>?
    private var musiciansLoadTask: Task<Void, Never>?
    private var musiciansSubscription: AnyCancellable?

    public init(
        model: EventModel,
        hasContextMenu: Bool,
        withDate: Bool = false,
        withPrice: Bool = true,
        imageLoader: @escaping AsyncImageLoader,
        favoritesStorage: FavoritesStorage<String>,
        calendarEventsManager: CalendarEventsManager,
        musiciansProvider: MusiciansProvider?
    ) {
        self.model = model
        self.eventId = model.id
        self.occurrenceIdentifier = eventOccurrenceIdentifier(for: model)
        self.imageLoader = imageLoader
        self.favoritesStorage = favoritesStorage
        self.calendarEventsManager = calendarEventsManager
        self.musiciansProvider = musiciansProvider
        self.hasContextMenu = hasContextMenu
        self.hasDate = withDate
        self.hasPrice = withPrice
    }

    /// Обновляет данные события при повторном `produce` из фабрики с актуальной моделью API.
    func replaceModel(_ model: EventModel) {
        guard eventOccurrenceIdentifier(for: model) == occurrenceIdentifier else { return }
        self.model = model
    }

    /// Загружает музыкантов события — только для экрана деталей.
    public func loadMusiciansIfNeeded() {
        guard musicians.isEmpty else { return }
        guard musiciansProvider != nil else { return }
        guard musiciansLoadTask == nil else { return }

        musiciansLoadTask = Task { [weak self] in
            await self?.loadMusicians()
        }
    }

    public func cancelMusiciansLoad() {
        guard musicians.isEmpty else { return }
        musiciansLoadTask?.cancel()
        musiciansLoadTask = nil
        musiciansSubscription?.cancel()
        musiciansSubscription = nil
    }

    private func loadMusicians() async {
        defer {
            musiciansLoadTask = nil
        }

        guard !Task.isCancelled else { return }
        guard let musiciansProvider else { return }

        do {
            let publisher = try await musiciansProvider(model.id)
            guard !Task.isCancelled else { return }
            musiciansSubscription = publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] loaded in
                    self?.musicians = loaded
                }
        } catch {
            guard !Task.isCancelled else { return }
        }
    }
}

// MARK: - RemoteImageLoadable

extension EventViewModel: RemoteImageLoadable {
    public var asyncImageLoader: AsyncImageLoader { imageLoader }
    public var remoteImageURL: String? { imageUrlString }
}

// MARK: - Identifiable

extension EventViewModel: Identifiable {
    public nonisolated var id: String { occurrenceIdentifier }
}

// MARK: - Hashable

extension EventViewModel: Hashable {
    public nonisolated static func == (lhs: EventViewModel, rhs: EventViewModel) -> Bool {
        lhs.occurrenceIdentifier == rhs.occurrenceIdentifier
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(occurrenceIdentifier)
    }
}
