//
//  UIScreen.swift
//  Core
//
//  Created by Tigran Danielian on 03.07.2025.
//

import UIKit

public extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size

   /// Верхний safe area активного окна (статус-бар / Dynamic Island).
   static var safeAreaTop: CGFloat {
       activeKeyWindow?.safeAreaInsets.top ?? 0
   }

   private static var activeKeyWindow: UIWindow? {
       let windows = UIApplication.shared.connectedScenes
           .compactMap { $0 as? UIWindowScene }
           .flatMap(\.windows)
       return windows.first(where: \.isKeyWindow) ?? windows.first
   }
}
