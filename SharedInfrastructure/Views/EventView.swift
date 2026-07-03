//
//  EventView.swift
//  Core
//
//  Created by Tigran Danielian on 02.07.2025.
//

import SwiftUI
import Core

public struct EventCardTapKey: EnvironmentKey {
    public static let defaultValue: (() -> Void)? = nil
}

public extension EnvironmentValues {
    var eventCardTap: (() -> Void)? {
        get { self[EventCardTapKey.self] }
        set { self[EventCardTapKey.self] = newValue }
    }
}

public struct EventView: View {
    @ObservedObject public var viewModel: EventViewModel
    @Environment(\.eventCardTap) private var eventCardTap

    public init(viewModel: EventViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        cardBody
            .eventCardContextMenu(viewModel: viewModel)
    }

    private var cardBody: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(uiImage: viewModel.image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .background(Color.secondary)
                    .cornerRadius(8)

                if viewModel.isLoadingImage {
                    SkeletonView()
                        .cornerRadius(8)
                }
            }
            .frame(width: 100, height: 100)
            .eventHeroTransitionSource(
                sourceID: EventHeroTransitionSourceID.card(
                    occurrenceIdentifier: viewModel.occurrenceIdentifier
                )
            )
            .onAppear { viewModel.loadImageIfNeeded() }
            .onDisappear { viewModel.cancelImageLoad() }

            EventInfoView(viewModel: viewModel)
                .frame(maxHeight: .infinity, alignment: .top)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
        .background(Color(uiColor: viewModel.isTop ? Colors.topEvent : Colors.cardBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
        .shadow(radius: 8)
        .contentShape(Rectangle())
        .modifier(EventCardTapModifier(action: eventCardTap))
    }
}

private struct EventCardTapModifier: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}
