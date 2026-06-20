//
//  Colors.swift
//  Core
//
//  Created by Tigran Danielian on 29.05.2025.
//

import UIKit

public enum Colors {
    // MARK: - Palette

    /// Background — #0A1020
    public static var background: UIColor {
        UIColor(hex: "0A1020")
    }

    /// Surface — #151D33
    public static var surface: UIColor {
        UIColor(hex: "151D33")
    }

    /// Surface Elevated — #202A45
    public static var secondarySurface: UIColor {
        UIColor(hex: "202A45")
    }

    /// Indigo Accent — #5B6CFF
    public static var accent: UIColor {
        UIColor(hex: "5B6CFF")
    }

    /// Soft Gold — #D5AE6B
    public static var softGold: UIColor {
        UIColor(hex: "D5AE6B")
    }

    /// Text — #F4F5F7
    public static var textPrimary: UIColor {
        UIColor(hex: "F4F5F7")
    }

    /// Приглушённый текст (производный от палитры).
    public static var textSecondary: UIColor {
        UIColor(hex: "939BAB")
    }

    /// Текст на индиго-акцентном фоне (кнопки, чипы).
    public static var textOnAccent: UIColor { textPrimary }

    /// Фон дневного блока — темнее elevated surface.
    public static var dayBlock: UIColor {
        UIColor(hex: "101828")
    }

    /// Верх градиента дневного блока.
    public static var dayBlockGradientTop: UIColor {
        UIColor(hex: "141B2E")
    }

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
    public static var accentSheet: UIColor { softGold }
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

    /// Время на карточках — Soft Gold.
    public static var timeTag: UIColor {
        softGold
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
