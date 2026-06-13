//
//  UIViewController+TopPresenter.swift
//  SharedInfrastructure
//

import UIKit

enum TopPresenter {
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let windowScene = scene else { return nil }
        let root = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? windowScene.windows.first?.rootViewController
        return topViewController(from: root)
    }

    static func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }

    static func configurePopover(for alert: UIAlertController, presenter: UIViewController) {
        guard let popover = alert.popoverPresentationController else { return }
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        popover.permittedArrowDirections = []
    }
}
