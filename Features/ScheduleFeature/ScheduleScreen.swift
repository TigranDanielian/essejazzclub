//
//  ScheduleScreen.swift
//  API
//
//  Created by Tigran Danielian on 30.05.2025.
//

import SwiftUI
import Services
import Combine
import Core
import SharedInfrastructure

public protocol ScheduleScreenDependencies {
    var eventsService: EventsService { get }
    var favoritesStorage: FavoritesStorage<String> { get }
}

public struct ScheduleScreen: View {
    private var actionHandler: (ScheduleScreenAction) -> Void
    private var uiFactory: any UIFactory
    private var onOpenFilter: () -> Void
    @StateObject var viewModel: ScheduleScreenViewModel
    
    @State private var isHeaderHidden = false
    @State private var initialOffset: CGFloat?

    public init(
        viewModel: ScheduleScreenViewModel,
        uiFactory: any UIFactory,
        actionHandler: @escaping (ScheduleScreenAction) -> Void,
        onOpenFilter: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
        self.actionHandler = actionHandler
        self.onOpenFilter = onOpenFilter
    }
    
    public var body: some View {
        VStack {
                HStack {
                    AnyView(uiFactory.produce(unit: .searchTextField($viewModel.searchInputText)))
                        .padding(.trailing, 4)

                    Button {
                        onOpenFilter()
                    } label: {
                        Image(uiImage: UIImage(resource: .filter).withRenderingMode(.alwaysTemplate))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color(uiColor: Colors.secondaryText))
                            .cornerRadius(8)
                    }
                }
                .padding(12)
                .opacity(isHeaderHidden ? 0 : 1)
                .offset(y: isHeaderHidden ? -20 : 0)

                ScrollView {
                    GeometryReader { geo in
                        print(geo.frame(in: .global).minY)
                        return Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .global).minY
                            )
                    }
                    .frame(height: 1)

                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.grouped) { day in
                            ScheduleDayView(
                                eventsDay: day,
                                actionHandler: { actionHandler(.event($0)) },
                                uiFactory: uiFactory
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 20)
                }
            }
            .background(Color(uiColor: Colors.mainBackground))
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if initialOffset == nil {
                    initialOffset = value
                    return
                }

                let offset = value - (initialOffset ?? 0)
                print("offset:", offset)

                if offset < -20, !isHeaderHidden {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHeaderHidden = true
                    }
                } else if offset > -5, isHeaderHidden {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHeaderHidden = false
                    }
                }
            }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
