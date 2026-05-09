//
//  LaunchView.swift
//  EsseJazzClub
//

import SwiftUI
import API

struct LaunchView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var appState: AppState

    @State private var alertInfo: AlertInfo?
    @State private var isAnimating = false

    var body: some View {
        ShimmeringImage()
            .scaleEffect(isAnimating ? 2.0 : 1.0)
            .opacity(isAnimating ? 0 : 1)
            .animation(.easeInOut(duration: 0.5), value: isAnimating)
            .onAppear {
                retryLoading()
            }
            .alert(item: $alertInfo) { info in
                Alert(
                    title: Text(info.title),
                    message: Text(info.message),
                    dismissButton: .default(Text("Повторить"), action: {
                        retryLoading()
                    })
                )
            }
    }

    @MainActor
    private func retryLoading() {
        container.loadEssentialData { result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isAnimating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        appState.isReady = true
                    }
                }
            case .failure(let error):
                alertInfo = AlertInfo(title: "Ошибка", message: (error as? ApiError)?.localizedDescription ?? "Неизвестная ошибка")
            }
        }
    }
}

private struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ShimmeringImage: View {
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        Image(ImageResource.logoBlackEng)
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 40)
            .overlay(
                shimmer
                    .mask(Image(ImageResource.logoBlackEng).resizable().scaledToFit())
            )
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 2.0
                }
            }
    }

    private var shimmer: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.6), Color.clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset * 300)
        .rotationEffect(.degrees(20))
    }
}
