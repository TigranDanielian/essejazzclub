//
//  ToastPresenter.swift
//  SharedInfrastructure
//

import Combine
import SwiftUI

@MainActor
public final class ToastPresenter: ObservableObject {
    public struct Toast: Equatable, Identifiable {
        public let id = UUID()
        public let message: String
    }

    @Published public private(set) var current: Toast?

    private var dismissTask: Task<Void, Never>?

    public nonisolated init() {}

    public func show(_ message: String) {
        dismissTask?.cancel()

        let toast = Toast(message: message)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            current = toast
        }

        let toastID = toast.id
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled, current?.id == toastID else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                current = nil
            }
        }
    }
}
