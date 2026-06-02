//
//  LaunchView.swift
//  EsseJazzClub
//

import SwiftUI
import API
import Core

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appMainBackground)
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
                alertInfo = AlertInfo(title: "Не удалось загрузить данные", message: error.localizedDescription)
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
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.appText)
            .padding(.horizontal, 40)
            .overlay(
                shimmer
                    .mask(
                        Image(ImageResource.logoBlackEng)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                    )
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
            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.45), Color.clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset * 300)
        .rotationEffect(.degrees(20))
    }
}
