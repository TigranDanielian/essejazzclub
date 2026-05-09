//
//  RootView+Routing.swift
//  EsseJazzClub
//

import Services
import SharedInfrastructure

extension RootView {
    private func makeEventDetailViewModel(from model: EventModel) -> EventViewModel? {
        container.viewModelFactory.produce(
            unit: .event(hasContextMenu: true, hasDate: true, model)
        ) as? EventViewModel
    }

    func resolveEventDetailViewModel(occurrenceIdentifier: String, caches: any EventOccurrenceRoutingCaches) -> EventViewModel? {
        if let cached = caches.cachedEventViewModel(forOccurrenceIdentifier: occurrenceIdentifier) {
            return cached
        }
        guard let model = container.eventsService.eventModel(forOccurrenceIdentifier: occurrenceIdentifier) else {
            return nil
        }
        return makeEventDetailViewModel(from: model)
    }

    func resolveMusicianViewModel(musicianId: Int, caches: any EventOccurrenceRoutingCaches) -> MusicianViewModel? {
        if let cached = caches.cachedMusicianViewModel(for: musicianId) {
            return cached
        }
        guard let musician = container.musiciansService.musician(forId: musicianId) else {
            return nil
        }
        return container.viewModelFactory.produce(unit: .musician(musician)) as? MusicianViewModel
    }

    func handleSharedNonRouting(_ action: EventAction) {
        switch action {
        case .contextAction(let contextAction):
            switch contextAction {
            case .calendar(let viewModel):
                container.calendarCoordinator.handleAction(with: viewModel)
            case .favorite(let id):
                container.favoritesStorage.toggleState(forValue: id, forKey: .events)
            case .share, .details:
                break
            }
        case .onBuy:
            break
        default:
            break
        }
    }

    func homeHandleAction(_ action: EventAction) {
        handleSharedNonRouting(action)
        switch action {
        case .contextAction(.details(let viewModel)):
            homeNavigationRouter.presentEventDetail(viewModel)
        case .onSelect(let viewModel):
            homeNavigationRouter.presentEventDetail(viewModel)
        case .onMusician(let viewModel):
            homeNavigationRouter.presentMusicianDetail(viewModel)
        case .dismiss:
            homeNavigationRouter.dismissPresentedOrPop()
        default:
            break
        }
    }

    func scheduleHandleAction(_ action: EventAction) {
        handleSharedNonRouting(action)
        switch action {
        case .contextAction(.details(let viewModel)):
            scheduleNavigationRouter.presentEventDetail(viewModel)
        case .onSelect(let viewModel):
            scheduleNavigationRouter.presentEventDetail(viewModel)
        case .onMusician(let viewModel):
            scheduleNavigationRouter.presentMusicianDetail(viewModel, presentation: .sheet)
        case .dismiss:
            scheduleNavigationRouter.dismissPresentedOrPop()
        default:
            break
        }
    }
}
