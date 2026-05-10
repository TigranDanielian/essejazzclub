//
//  SharedUIFactory.swift
//  Core
//
//  Created by Tigran Danielian on 02.07.2025.
//

import Foundation
import Services
import SwiftUI
import Core

public typealias AsyncImageLoader = (String) async throws -> UIImage?

enum SharedUnitFactory {
    case viewModels
    case ui
}

public enum UIUnit {
    case event(EventViewModel)
    case eventDetails(EventViewModel, EventActionHandler)
    case musician(MusicianViewModel, MusicianActionHandler)
    case searchTextField(Binding<String>)
    case empty
}

public enum ViewModelUnit {
    case event(hasContextMenu: Bool = false, hasDate: Bool = false, EventModel)
    case musician(Musician)
}

public protocol UIFactory: ObservableObject {
    associatedtype Content: View
    
    func produce(unit: UIUnit) -> Content
}

public protocol ViewModelFactory: AnyObject {
    func produce(unit: ViewModelUnit) -> any ObservableObject

    /// VM события, удерживаемые на время навигации (см. `retain…` / `synchronize…`). По умолчанию нет кэша.
    func cachedEventViewModelForNavigation(forOccurrenceIdentifier: String) -> EventViewModel?
    func cachedMusicianViewModelForNavigation(for musicianId: Int) -> MusicianViewModel?
    func retainEventViewModelForNavigation(_ viewModel: EventViewModel)
    func retainMusicianViewModelForNavigation(_ viewModel: MusicianViewModel)
    /// Оставляет в кэше только ключи из объединения активных маршрутов (например, обе вкладки).
    func synchronizeNavigationCaches(allowedOccurrenceIdentifiers: Set<String>, allowedMusicianIds: Set<Int>)
}

public extension ViewModelFactory {
    func cachedEventViewModelForNavigation(forOccurrenceIdentifier: String) -> EventViewModel? { nil }
    func cachedMusicianViewModelForNavigation(for musicianId: Int) -> MusicianViewModel? { nil }
    func retainEventViewModelForNavigation(_ viewModel: EventViewModel) {}
    func retainMusicianViewModelForNavigation(_ viewModel: MusicianViewModel) {}
    func synchronizeNavigationCaches(allowedOccurrenceIdentifiers: Set<String>, allowedMusicianIds: Set<Int>) {}
}

public final class SharedUIFactory: UIFactory {
    public init() {}
    
    @ViewBuilder
    public func produce(unit: UIUnit) -> some View {
        switch unit {
        case .event(let viewModel):
            EventView(viewModel: viewModel)
        case .eventDetails(let viewModel, let actionHandler):
            EventDetailView(viewModel: viewModel, actionHandler: actionHandler)
        case .searchTextField(let binding):
            SearchTextField(textInput: binding)
        case .musician(let viewModel, let actionHandler):
            MusicianDetailsView(viewModel: viewModel, actionHandler: actionHandler)
        case .empty:
            EmptyView()
        }
    }
}

