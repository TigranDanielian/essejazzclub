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
    case searchTextField(Binding<String>)
}

public enum ViewModelUnit {
    case event(hasContextMenu: Bool = false, hasDate: Bool = false, EventModel)
}

public protocol UIFactory: ObservableObject {
    associatedtype Content: View
    
    func produce(unit: UIUnit) -> Content
}

public protocol ViewModelFactory {
    func produce(unit: ViewModelUnit) -> any ObservableObject
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
        }
    }
}

