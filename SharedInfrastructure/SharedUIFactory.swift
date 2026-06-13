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
        onSelectUpcomingOccurrence: ((String) -> Void)?
    )
    case musician(MusicianViewModel, MusicianActionHandler)
    case favoriteConcertRow(FavoriteConcertRow)
    case favoriteMusicianRow(FavoriteMusicianRow)
    case searchTextField(Binding<String>, prompt: String)
    case empty
}

public enum ViewModelUnit {
    case event(hasContextMenu: Bool = false, hasDate: Bool = false, EventModel)
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
        case .eventDetails(let viewModel, let actionHandler, let upcomingOccurrences, let displayOptions, onSelectUpcomingOccurrence: let onSelectUpcoming):
            EventDetailView(
                viewModel: viewModel,
                actionHandler: actionHandler,
                upcomingOccurrences: upcomingOccurrences,
                displayOptions: displayOptions,
                onSelectUpcomingOccurrence: onSelectUpcoming
            )
        case .favoriteConcertRow(let row):
            FavoriteConcertRowView(row: row, imageLoader: imageLoader)
        case .favoriteMusicianRow(let row):
            FavoriteMusicianRowView(row: row, imageLoader: imageLoader)
        case .searchTextField(let binding, let prompt):
            SearchTextField(textInput: binding, prompt: prompt)
        case .musician(let viewModel, let actionHandler):
            MusicianDetailsView(viewModel: viewModel, actionHandler: actionHandler)
        case .empty:
            EmptyView()
        }
    }
}

