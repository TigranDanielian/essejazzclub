//
//  ScheduleEventView.swift
//  ScheduleFeature
//

import SwiftUI
import SharedInfrastructure

struct ScheduleEventView: View {
    @ObservedObject var viewModel: EventViewModel
    var onSelect: EventActionHandler = { _ in }

    init(
        viewModel: EventViewModel,
        onSelect: @escaping EventActionHandler = { _ in }
    ) {
        self.viewModel = viewModel
        self.onSelect = onSelect
    }

    var body: some View {
        EventView(viewModel: viewModel)
            .environment(\.eventCardTap, openEventDetails)
    }

    private func openEventDetails() {
        onSelect(.navigation(.onEventDetails(
            viewModel,
            heroTransitionSourceID: EventHeroTransitionSourceID.card(
                occurrenceIdentifier: viewModel.occurrenceIdentifier
            )
        )))
    }
}
