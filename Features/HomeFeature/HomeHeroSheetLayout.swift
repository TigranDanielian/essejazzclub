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

    /// Отступ прогресс-бара stories от низа баннера.
    public static var storyProgressBottomInset: CGFloat {
        pageIndicatorBottomInset + pageIndicatorLift
    }

    /// Шит наезжает на баннер до линии индикатора.
    public static var sheetOverlap: CGFloat {
        pageIndicatorBottomInset
    }

    /// Зона баннера над шитом: скролл расширяет hit-testing вверх на эту высоту.
    public static var scrollHitExtensionHeight: CGFloat {
        sliderHeight - sheetOverlap
    }

    /// Длительность одного «сторис»-слайда в герой-баннере.
    public static let storyDuration: TimeInterval = 7
}
