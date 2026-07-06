//
//  ToastOverlay.swift
//  SharedInfrastructure
//

import SwiftUI
import Core

public struct ToastOverlay: View {
    @ObservedObject private var presenter: ToastPresenter

    public init(presenter: ToastPresenter) {
        self.presenter = presenter
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let toast = presenter.current {
                Text(toast.message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.black.opacity(0.18))
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
                    .padding(.horizontal, 56)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: presenter.current?.id)
    }
}
