//
//  EventOptionsButton.swift
//  SharedInfrastructure
//

import SwiftUI
import UIKit
import Core

public enum EventOptionsButtonMetrics {
    public static let iconSize: CGFloat = 16
    public static let innerPadding: CGFloat = 2
    public static let outerPadding: CGFloat = 8
    public static var controlSize: CGFloat {
        iconSize + innerPadding * 2 + outerPadding * 2
    }
}

/// UIKit-кнопка «⋯» — стабильнее в `ScrollView`/`LazyVStack`, чем SwiftUI `Button`.
public struct EventOptionsButton: UIViewRepresentable {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    public func makeUIView(context: Context) -> OptionsControlView {
        let view = OptionsControlView()
        view.coordinator = context.coordinator
        view.configure()
        return view
    }

    public func updateUIView(_ uiView: OptionsControlView, context: Context) {
        context.coordinator.action = action
        uiView.coordinator = context.coordinator
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: OptionsControlView, context: Context) -> CGSize? {
        CGSize(width: EventOptionsButtonMetrics.controlSize, height: EventOptionsButtonMetrics.controlSize)
    }

    public final class OptionsControlView: UIView {
        weak var coordinator: Coordinator?
        private let button = UIButton(type: .system)

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = true
            backgroundColor = .clear
            addSubview(button)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure() {
            var configuration = UIButton.Configuration.plain()
            configuration.image = Self.optionsImage()
            configuration.baseForegroundColor = Colors.accentSheet
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: EventOptionsButtonMetrics.outerPadding + EventOptionsButtonMetrics.innerPadding,
                leading: EventOptionsButtonMetrics.outerPadding + EventOptionsButtonMetrics.innerPadding,
                bottom: EventOptionsButtonMetrics.outerPadding + EventOptionsButtonMetrics.innerPadding,
                trailing: EventOptionsButtonMetrics.outerPadding + EventOptionsButtonMetrics.innerPadding
            )
            button.configuration = configuration
            button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        }

        public override var intrinsicContentSize: CGSize {
            CGSize(width: EventOptionsButtonMetrics.controlSize, height: EventOptionsButtonMetrics.controlSize)
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            button.frame = bounds
        }

        public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            guard isUserInteractionEnabled, !isHidden, alpha > 0.01, bounds.contains(point) else { return nil }
            let local = convert(point, to: button)
            return button.point(inside: local, with: event) ? button : nil
        }

        @objc private func tapped() {
            coordinator?.action()
        }

        private static func optionsImage() -> UIImage {
            let source = UIImage(resource: .options).withRenderingMode(.alwaysTemplate)
            let side = EventOptionsButtonMetrics.iconSize
            let size = CGSize(width: side, height: side)
            return UIGraphicsImageRenderer(size: size).image { _ in
                source.draw(in: CGRect(origin: .zero, size: size))
            }.withRenderingMode(.alwaysTemplate)
        }
    }

    public final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }
    }
}
