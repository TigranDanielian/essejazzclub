//
//  ClubFavoriteEventDetailHost.swift
//  ClubFeature
//

import SwiftUI
import Services
import Core
import SharedInfrastructure

/// Оболочка над `ClubFavoriteEventDetailViewModel` + `eventDetails` из фабрики.
struct ClubFavoriteEventDetailHost: View {
    @ObservedObject var clubScreen: ClubScreenViewModel

    @StateObject private var detail: ClubFavoriteEventDetailViewModel

    init(occurrenceIdentifier: String, mode: ClubNavigationRouter.FavoriteEventDetailMode, clubScreen: ClubScreenViewModel) {
        self.clubScreen = clubScreen
        _detail = StateObject(
            wrappedValue: ClubFavoriteEventDetailViewModel(
                dependencies: clubScreen.dependencies,
                clubScreen: clubScreen,
                occurrenceIdentifier: occurrenceIdentifier,
                mode: mode
            )
        )
    }

    var body: some View {
        if let eventVM = detail.eventViewModel {
            AnyView(
                detail.dependencies.uiFactory.produce(
                    unit: .eventDetails(
                        eventVM,
                        detail.makeEventActionHandler(),
                        detail.upcomingOccurrences,
                        detail.detailDisplayOptions,
                        onSelectUpcomingOccurrence: detail.onSelectUpcomingOccurrence
                    )
                )
            )
        } else {
            loadingPlaceholder
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
