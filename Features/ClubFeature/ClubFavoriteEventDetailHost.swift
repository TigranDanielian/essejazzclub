//
//  ClubFavoriteEventDetailHost.swift
//  ClubFeature
//

import SwiftUI
import Services
import Core
import SharedInfrastructure

/// Деталка события из вкладки «Клуб» с блоком ближайших дат по всем слотам `eventId`.
struct ClubFavoriteEventDetailHost: View {
    let occurrenceIdentifier: String
    @ObservedObject var router: ClubNavigationRouter
    let dependencies: ClubScreenDependencies

    @State private var events: [EventModel] = []

    var body: some View {
        Group {
            if let model = events.first(where: { eventOccurrenceIdentifier(for: $0) == occurrenceIdentifier }),
               let viewModel = dependencies.viewModelFactory.produce(
                unit: .event(hasContextMenu: false, hasDate: true, model)
               ) as? EventViewModel {
                let extras = ClubFavoriteEventSchedule.upcomingForDetail(
                    forEventId: model.id,
                    in: events,
                    excludingCurrentOccurrenceIdentifier: occurrenceIdentifier
                )
                AnyView(
                    dependencies.uiFactory.produce(
                        unit: .eventDetails(
                            viewModel,
                            makeEventActionHandler(),
                            extras.isEmpty ? nil : extras
                        )
                    )
                )
            } else {
                loadingPlaceholder
            }
        }
        .onReceive(dependencies.eventsService.state) { state in
            events = state.events
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Загрузка события…")
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
    }

    private func makeEventActionHandler() -> EventActionHandler {
        { action in
            applyEventActionParts(
                action,
                applyNavigation: { nav in
                    switch nav {
                    case .dismiss:
                        router.pop()
                    case .onMusicianDetails(let musician):
                        router.present(route: .musicianDetail(musician), presentation: .push)
                    case .onEventDetails(let vm):
                        router.present(
                            route: .favoriteEventDetail(occurrenceIdentifier: vm.occurrenceIdentifier),
                            presentation: .push
                        )
                    case .onBuy:
                        break
                    }
                },
                handleContextButton: handleContext
            )
        }
    }

    private func handleContext(_ type: EventContextButtonType) {
        switch type {
        case .calendar(let viewModel):
            dependencies.calendarCoordinator.handleAction(with: viewModel)
        case .favorite(let id):
            dependencies.favoritesStorage.toggleState(forValue: id, forKey: .events)
        case .share:
            break
        case .details:
            break
        }
    }
}
