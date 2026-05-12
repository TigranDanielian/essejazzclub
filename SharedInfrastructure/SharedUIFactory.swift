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
    case eventDetails(
        EventViewModel,
        EventActionHandler,
        [EventDetailUpcomingOccurrence]?,
        EventDetailDisplayOptions,
        onSelectUpcomingOccurrence: ((String) -> Void)?
    )
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
}

public final class SharedUIFactory: UIFactory {
    public init() {}
    
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
        case .searchTextField(let binding):
            SearchTextField(textInput: binding)
        case .musician(let viewModel, let actionHandler):
            MusicianDetailsView(viewModel: viewModel, actionHandler: actionHandler)
        case .empty:
            EmptyView()
        }
    }
}

