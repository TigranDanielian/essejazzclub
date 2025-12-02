//
//  Colors.swift
//  Core
//
//  Created by Tigran Danielian on 29.05.2025.
//

import UIKit

public enum Colors {
    public static var primary: UIColor {
        return UIColor(hex: "F73859")
    }
    
    public static var accentSheet: UIColor {
        return UIColor(hex: "C3B091")
    }
    
    public static var mainBackground: UIColor {
        return UIColor(hex: "313131")
    }
    
    public static var altBackground: UIColor {
        return UIColor(hex: "414141")
    }
    
    public static var text: UIColor {
        return UIColor(hex: "F0F5F9")
    }
    
    public static var secondaryText: UIColor {
        return UIColor(hex: "C9D6DF")
    }
    
    public static var cardBackground: UIColor {
        return UIColor(hex: "525252")
    }
    
    public static var textInverted: UIColor {
        return UIColor(hex: "F0F5F9")
    }
    
    
    public static var timeTag: UIColor {
        return UIColor(hex: "00909E")
    }
    
    public static var freetag: UIColor {
        return UIColor(hex: "61B15A")
    }
}

private extension UIColor {
    convenience init(hex string: String) {
      var hex = string.hasPrefix("#")
        ? String(string.dropFirst())
        : string
      guard hex.count == 3 || hex.count == 6
        else {
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
        red:   CGFloat((intCode >> 16) & 0xFF) / 255.0,
        green: CGFloat((intCode >> 8) & 0xFF) / 255.0,
        blue:  CGFloat((intCode) & 0xFF) / 255.0, alpha: 1.0)
    }
}

extension UIColor {
    var hexString: String? {
        guard let components = self.cgColor.components else {
            return nil
        }
        
        if components.count == 2 {
            let white = components[0]
            let alpha = components[1]
            return String(format: "%02X%02X%02X%02X", (Int)(white * 255), (Int)(white * 255), (Int)(white * 255), (Int)(alpha * 255))
        } else {
            let r = components[0]
            let g = components[1]
            let b = components[2]
            return String(format: "%02X%02X%02X", (Int)(r * 255), (Int)(g * 255), (Int)(b * 255))
        }
    }
}
