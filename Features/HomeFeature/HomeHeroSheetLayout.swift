//
//  HomeHeroSheetLayout.swift
//  HomeFeature
//

import UIKit

/// Геометрия главного экрана с герой-баннером и шитом.
///
/// Z-order (снизу вверх):
/// 1. Фон
/// 2. Баннер
/// 3. Scroll — на всю высоту; в покое верхняя часть прозрачна и пропускает тапы на баннер.
///    Контент шита (скруглённый верх) начинается на `sheetTop`.
public enum HomeHeroSheetLayout {
    /// Высота баннера.
    public static let bannerHeight: CGFloat = 350

    /// @deprecated Используйте `bannerHeight`.
    public static let sliderHeight: CGFloat = bannerHeight

    public static let sheetCornerRadius: CGFloat = 24

    /// Расстояние от низа баннера до page control.
    public static let pageIndicatorBottomInset: CGFloat = 24

    /// Подъём page control над исходной позицией.
    public static let pageIndicatorLift: CGFloat = 8

    public static var storyProgressBottomInset: CGFloat {
        pageIndicatorBottomInset + pageIndicatorLift
    }

    /// На сколько шит наезжает на баннер (до линии page control).
    public static var sheetOverlap: CGFloat {
        pageIndicatorBottomInset
    }

    /// Y верхнего края шита от верха экрана (в покое, offset = 0).
    public static var sheetTop: CGFloat {
        bannerHeight - sheetOverlap
    }

    /// Высота прозрачной зоны scroll над шитом (= зона баннера под scroll).
    public static var scrollPassthroughHeight: CGFloat {
        sheetTop
    }

    /// @deprecated Используйте `scrollPassthroughHeight`.
    public static var scrollHitExtensionHeight: CGFloat {
        scrollPassthroughHeight
    }

    public static let storyDuration: TimeInterval = 7
}
