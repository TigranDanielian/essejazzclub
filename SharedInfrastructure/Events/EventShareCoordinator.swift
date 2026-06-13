//
//  EventShareCoordinator.swift
//  SharedInfrastructure
//

import UIKit

public enum EventShareCoordinator {
    @MainActor
    public static func share(_ viewModel: EventViewModel) {
        let url = viewModel.websiteURL
        guard let presenter = TopPresenter.topViewController() else { return }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        presenter.present(activity, animated: true)
    }
}
