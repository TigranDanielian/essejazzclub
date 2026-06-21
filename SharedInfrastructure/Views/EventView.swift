//
//  EventView.swift
//  Core
//
//  Created by Tigran Danielian on 02.07.2025.
//

import SwiftUI
import Core

public struct EventSwipeToggleKey: EnvironmentKey {
    public static let defaultValue: (() -> Void)? = nil
}

public struct EventCardTapKey: EnvironmentKey {
    public static let defaultValue: (() -> Void)? = nil
}

public struct EventShowsOptionsButtonKey: EnvironmentKey {
    public static let defaultValue: Bool = true
}

public extension EnvironmentValues {
    var eventSwipeToggle: (() -> Void)? {
        get { self[EventSwipeToggleKey.self] }
        set { self[EventSwipeToggleKey.self] = newValue }
    }

    var eventCardTap: (() -> Void)? {
        get { self[EventCardTapKey.self] }
        set { self[EventCardTapKey.self] = newValue }
    }

    var eventShowsOptionsButton: Bool {
        get { self[EventShowsOptionsButtonKey.self] }
        set { self[EventShowsOptionsButtonKey.self] = newValue }
    }
}

public struct EventView: View {
    @ObservedObject public var viewModel: EventViewModel
    @Environment(\.eventSwipeToggle) private var eventSwipeToggle
    @Environment(\.eventCardTap) private var eventCardTap
    @Environment(\.eventShowsOptionsButton) private var eventShowsOptionsButton

    public init(viewModel: EventViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            cardBody

            if eventShowsOptionsButton, viewModel.hasContextMenu, let eventSwipeToggle {
                Button(action: eventSwipeToggle) {
                    Image(uiImage: UIImage(resource: .options).withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding(2)
                        .foregroundStyle(Color(uiColor: Colors.accentSheet))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .padding(8)
                .zIndex(1)
            }
        }
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
        .onTapGesture {
            eventCardTap?()
        }
    }
}
