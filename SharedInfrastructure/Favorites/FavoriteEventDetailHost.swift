//
//  FavoriteEventDetailHost.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

public struct FavoriteEventDetailHost: View {
    @StateObject private var detail: FavoriteEventDetailViewModel

    public init(
        occurrenceIdentifier: String,
        mode: FavoriteEventDetailMode,
        dependencies: FavoriteEventDetailDependencies,
        navigation: FavoriteEventDetailNavigating
    ) {
        _detail = StateObject(
            wrappedValue: FavoriteEventDetailViewModel(
                dependencies: dependencies,
                navigation: navigation,
                occurrenceIdentifier: occurrenceIdentifier,
                mode: mode
            )
        )
    }

    public var body: some View {
        Group {
            if let eventViewModel = detail.eventViewModel {
                AnyView(
                    detail.dependencies.uiFactory.produce(
                        unit: .eventDetails(
                            eventViewModel,
                            detail.makeEventActionHandler(),
                            detail.upcomingOccurrences,
                            detail.detailDisplayOptions,
                            heroTransitionSourceID: nil,
                            onSelectUpcomingOccurrence: detail.onSelectUpcomingOccurrence
                        )
                    )
                )
            } else {
                loadingPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Загрузка мероприятия…")
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
    }
}
