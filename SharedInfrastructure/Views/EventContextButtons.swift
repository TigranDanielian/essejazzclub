//
//  EventContextButtons.swift
//  ScheduleFeature
//
//  Created by Tigran Danielian on 16.06.2025.
//

import SwiftUI
import Combine
import Core

public struct EventContextButtons: View {
    @ObservedObject public var viewModel: EventViewModel
    public var onTap: (EventContextButtonType) -> Void
    
    public init(viewModel: EventViewModel, onTap: @escaping (EventContextButtonType) -> Void) {
        self.viewModel = viewModel
        self.onTap = onTap
    }
    
    public var body: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .top) {
                EventContextButton(viewModel: viewModel.favoriteButtonViewModel, onTap: { onTap(.favorite(viewModel.eventId)) })
                EventContextButton(viewModel: viewModel.calendarButtonViewModel, onTap: { onTap(.calendar(viewModel)) })
            }
            
            HStack(alignment: .top) {
                EventContextButton(viewModel: viewModel.shareButtonViewModel, onTap: { onTap(.share(viewModel)) })
                EventContextButton(viewModel: viewModel.detailsButtonViewModel, onTap: { onTap(.details(viewModel)) })
            }
        }
    }
}

@MainActor
public class EventContextButtonViewModel: ObservableObject {
    init(imagePublisher: AnyPublisher<UIImage?, Never>) {
        imagePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$image)
    }
    
    @Published var image: UIImage?
}

public enum EventContextButtonType {
    case favorite(String)
    case calendar(EventViewModel)
    case details(EventViewModel)
    case share(EventViewModel)

    var imageName: String {
        switch self {
        case .favorite:
            return "heart"
        case .calendar:
            return "calendar"
        case .details:
            return "info.circle"
        case .share:
            return "square.and.arrow.up"
        }
    }
}

struct EventContextButton: View {
    /// Родитель владеет `EventContextButtonViewModel` (как у избранного в `EventViewModel` / `MusicianViewModel`).
    @ObservedObject var viewModel: EventContextButtonViewModel
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            icon
                .frame(width: 16, height: 16)
                .foregroundColor(Color(uiColor: Colors.text))
                .padding(8)
                .background(Color(uiColor: Colors.cardBackground).opacity(0.92))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var icon: some View {
        if let uiImage = viewModel.image {
            Image(uiImage: uiImage)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "heart")
                .resizable()
                .scaledToFit()
        }
    }
}
