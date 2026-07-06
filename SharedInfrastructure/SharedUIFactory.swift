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

public enum UIUnit {
    case event(EventViewModel)
    case eventDetails(
        EventViewModel,
        EventActionHandler,
        [EventDetailUpcomingOccurrence]?,
        EventDetailDisplayOptions,
        heroTransitionSourceID: String?,
        onSelectUpcomingOccurrence: ((String) -> Void)?
    )
    case musician(MusicianViewModel, MusicianActionHandler, heroTransitionSourceID: String?)
    case favoriteConcertRow(FavoriteConcertRow)
    case favoriteMusicianRow(FavoriteMusicianRow)
    case searchTextField(Binding<String>, prompt: String, onClear: (() -> Void)? = nil)
    case empty
}

public enum ViewModelUnit {
    case event(hasContextMenu: Bool = false, hasDate: Bool = false, hasPrice: Bool = true, EventModel)
    case musician(Musician)
}

public protocol UIFactory {
    associatedtype Content: View

    @ViewBuilder
    func produce(unit: UIUnit) -> Content
}

@MainActor
public protocol ViewModelFactory: AnyObject {
    func produce(unit: ViewModelUnit) -> any ObservableObject
}

public final class SharedUIFactory: UIFactory {
    private let imageLoader: ImageLoader

    public init(imageLoader: ImageLoader) {
        self.imageLoader = imageLoader
    }

    @ViewBuilder
    public func produce(unit: UIUnit) -> some View {
        switch unit {
        case .event(let viewModel):
            EventView(viewModel: viewModel)
        case .eventDetails(let viewModel, let actionHandler, let upcomingOccurrences, let displayOptions, let heroTransitionSourceID, onSelectUpcomingOccurrence: let onSelectUpcoming):
            EventDetailView(
                viewModel: viewModel,
                actionHandler: actionHandler,
                upcomingOccurrences: upcomingOccurrences,
                displayOptions: displayOptions,
                heroTransitionSourceID: heroTransitionSourceID,
                onSelectUpcomingOccurrence: onSelectUpcoming
            )
        case .favoriteConcertRow(let row):
            FavoriteConcertRowView(row: row, imageLoader: imageLoader)
        case .favoriteMusicianRow(let row):
            FavoriteMusicianRowView(row: row, imageLoader: imageLoader)
        case .searchTextField(let binding, let prompt, let onClear):
            SearchTextField(textInput: binding, prompt: prompt, onClear: onClear)
        case .musician(let viewModel, let actionHandler, let heroTransitionSourceID):
            MusicianDetailsView(
                viewModel: viewModel,
                actionHandler: actionHandler,
                heroTransitionSourceID: heroTransitionSourceID
            )
        case .empty:
            EmptyView()
        }
    }
}

