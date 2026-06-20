//
//  TopLeftCutoutShape.swift
//  SharedInfrastructure
//
//  Created by Tigran Danielian on 02.12.2025.
//

import Foundation
import SwiftUI
import Core

public enum DayBlockBackground {
    public static var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: Colors.dayBlockGradientTop),
                Color(uiColor: Colors.dayBlock),
                Color(uiColor: Colors.background),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct TopLeftCutoutShape: Shape {
    let cutoutSize: CGSize
    let cornerRadius: CGFloat
    
    public init(cutoutSize: CGSize, cornerRadius: CGFloat) {
        self.cutoutSize = cutoutSize
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        // Вся карточка
        path.addRect(rect)

        // Вырез
        let cutRect = CGRect(origin: .zero, size: cutoutSize)

        var cutout = Path()
        cutout.move(to: CGPoint(x: cutRect.minX, y: cutRect.minY))
        cutout.addLine(to: CGPoint(x: cutRect.maxX + cornerRadius, y: cutRect.minY))
        cutout.addQuadCurve(
            to: CGPoint(x: cutRect.maxX, y: cutRect.minY + cornerRadius),
            control: CGPoint(x: cutRect.maxX, y: cutRect.minY)
        )
        
        cutout.addLine(to: CGPoint(x: cutRect.maxX, y: cutRect.maxY - cornerRadius))
        cutout.addQuadCurve(
            to: CGPoint(x: cutRect.maxX - cornerRadius, y: cutRect.maxY),
            control: CGPoint(x: cutRect.maxX, y: cutRect.maxY)
        )
        cutout.addLine(to: CGPoint(x: cutRect.minX + cornerRadius, y: cutRect.maxY))
        cutout.addQuadCurve(
            to: CGPoint(x: cutRect.minX, y: cutRect.maxY + cornerRadius),
            control: CGPoint(x: cutRect.minX, y: cutRect.maxY)
        )
        cutout.closeSubpath()

        path.addPath(cutout)

        return path
    }
}
