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
    private var actionHandler: EventActionHandler
    private var uiFactory: any UIFactory
    @StateObject var viewModel: ScheduleScreenViewModel

    @State private var showFilter: Bool = false

    public init(
        viewModel: ScheduleScreenViewModel,
        uiFactory: any UIFactory,
        actionHandler: @escaping EventActionHandler
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.uiFactory = uiFactory
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        return NavigationView {
            VStack {
                HStack {
                    AnyView(uiFactory.produce(unit: .searchTextField($viewModel.searchInputText)))
                        .padding(.trailing, 4)
                    Button {
                        showFilter = true
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
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.grouped) { day in
                            ScheduleDayView(eventsDay: day, actionHandler: actionHandler, uiFactory: uiFactory)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 20)
                }
            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("Афиша")
            .background(Color.init(uiColor: Colors.mainBackground))
        }
        .sheet(isPresented: $showFilter, content: {
            NavigationView {
                EmptyView()
            }
        })
    }
}
