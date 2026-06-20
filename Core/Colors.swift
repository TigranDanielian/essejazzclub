//
//  Colors.swift
//  Core
//
//  Created by Tigran Danielian on 29.05.2025.
//

import UIKit

public enum Colors {
    // MARK: - Palette

    /// Background — #111827
    public static var background: UIColor {
        UIColor(hex: "111827")
    }

    /// Surface — #1F2937
    public static var surface: UIColor {
        UIColor(hex: "1F2937")
    }

    /// Secondary Surface — #374151
    public static var secondarySurface: UIColor {
        UIColor(hex: "374151")
    }

    /// Accent — #D4A574
    public static var accent: UIColor {
        UIColor(hex: "D4A574")
    }

    /// Text Primary — #F9FAFB
    public static var textPrimary: UIColor {
        UIColor(hex: "F9FAFB")
    }

    /// Text Secondary — #9CA3AF
    public static var textSecondary: UIColor {
        UIColor(hex: "9CA3AF")
    }

    /// Текст на акцентном фоне (кнопки, чипы).
    public static var textOnAccent: UIColor { background }

    /// Топ-мероприятия (isTop) — глубокий тёмно-бордовый.
    public static var topEvent: UIColor {
        UIColor(hex: "452020")
    }

    /// Избранное — активное сердечко (коралловый).
    public static var favorite: UIColor {
        UIColor(hex: "FF6F61")
    }

    // MARK: - Semantic (legacy aliases)

    public static var mainBackground: UIColor { background }
    public static var cardBackground: UIColor { surface }
    public static var altBackground: UIColor { secondarySurface }
    public static var accentSheet: UIColor { accent }
    public static var text: UIColor { textPrimary }
    public static var textInverted: UIColor { textPrimary }
    public static var secondaryText: UIColor { textSecondary }
    public static var primary: UIColor { accent }
    public static var separator: UIColor { secondarySurface }
    public static var homeSection: UIColor { secondarySurface }

    /// Метка «бесплатно».
    public static var freetag: UIColor {
        UIColor(hex: "78A978")
    }

    /// Время на карточках — приглушённый акцент.
    public static var timeTag: UIColor {
        UIColor(hex: "B8956A")
    }
}

private extension UIColor {
    convenience init(hex string: String) {
        var hex = string.hasPrefix("#")
            ? String(string.dropFirst())
            : string
        guard hex.count == 3 || hex.count == 6 else {
            self.init(white: 1.0, alpha: 0.0)
            return
        }
        if hex.count == 3 {
            for (index, char) in hex.enumerated() {
                hex.insert(char, at: hex.index(hex.startIndex, offsetBy: index * 2))
            }
        }

        guard let intCode = Int(hex, radix: 16) else {
            self.init(white: 1.0, alpha: 0.0)
            return
        }

        self.init(
            red: CGFloat((intCode >> 16) & 0xFF) / 255.0,
            green: CGFloat((intCode >> 8) & 0xFF) / 255.0,
            blue: CGFloat(intCode & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

extension UIColor {
    var hexString: String? {
        guard let components = cgColor.components else {
            return nil
        }

        if components.count == 2 {
            let white = components[0]
            let alpha = components[1]
            return String(
                format: "%02X%02X%02X%02X",
                Int(white * 255),
                Int(white * 255),
                Int(white * 255),
                Int(alpha * 255)
            )
        }

        let r = components[0]
        let g = components[1]
        let b = components[2]
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
