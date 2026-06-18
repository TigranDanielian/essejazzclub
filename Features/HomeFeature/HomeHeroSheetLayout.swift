//
//  HomeHeroSheetLayout.swift
//  HomeFeature
//

import UIKit

public enum HomeHeroSheetLayout {
    public static let sliderHeight: CGFloat = 350
    public static let sheetCornerRadius: CGFloat = 24

    /// Расстояние от низа баннера до page control (до подъёма).
    public static let pageIndicatorBottomInset: CGFloat = 24
    /// На сколько поднять точки над исходным положением.
    public static let pageIndicatorLift: CGFloat = 8

    /// Шит наезжает на баннер до линии исходных точек.
    public static var sheetOverlap: CGFloat {
        pageIndicatorBottomInset
    }
}
