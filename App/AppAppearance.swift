//
//  AppAppearance.swift
//  EsseJazzClub
//

import UIKit
import Core

extension EsseJazzClubApp {
    func setupNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.mainBackground
        appearance.titleTextAttributes = [.foregroundColor: Colors.text]
        appearance.largeTitleTextAttributes = [.foregroundColor: Colors.text]

        let backImage = UIImage(systemName: "chevron.left")?
            .withTintColor(Colors.accent, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)

        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setBackButtonTitlePositionAdjustment(
            UIOffset(horizontal: -1000, vertical: 0),
            for: .default
        )
    }

    func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.mainBackground

        appearance.stackedLayoutAppearance.selected.iconColor = Colors.primary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: Colors.primary]

        appearance.stackedLayoutAppearance.normal.iconColor = Colors.secondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: Colors.secondaryText]

        let offset = UIOffset(horizontal: 0, vertical: 4)
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = offset
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = offset
        appearance.stackedItemPositioning = .automatic

        UITabBar.appearance().standardAppearance = appearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
