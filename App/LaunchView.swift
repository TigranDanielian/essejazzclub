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
    @State private var isExiting = false

    var body: some View {
        ZStack {
            LaunchSpotlightBackground(isExiting: isExiting)

            LaunchLogoView()
                .scaleEffect(isExiting ? 1.08 : 1.0)
                .opacity(isExiting ? 0 : 1)
                .animation(.easeInOut(duration: 0.55), value: isExiting)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        isExiting = false
        let loadStartedAt = Date()

        container.loadEssentialData { result in
            Task { @MainActor in
                switch result {
                case .success:
                    let elapsed = Date().timeIntervalSince(loadStartedAt)
                    if elapsed < 1 {
                        try? await Task.sleep(for: .seconds(1))
                    }

                    isExiting = true
                    try? await Task.sleep(for: .milliseconds(550))
                    appState.isReady = true
                case .failure(let error):
                    alertInfo = AlertInfo(title: "Не удалось загрузить данные", message: error.localizedDescription)
                }
            }
        }
    }
}

private struct LaunchSpotlightBackground: View {
    var isExiting: Bool

    @State private var beamIntensity: CGFloat = 0

    private let fadeInDuration: TimeInterval = 2.4
    private let secondaryDelay: TimeInterval = 0.55

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let primaryAngle = time * 0.42
            let primaryCenter = UnitPoint(
                x: 0.5 + cos(primaryAngle) * 0.32,
                y: 0.5 + sin(primaryAngle * 0.78) * 0.36
            )
            let secondaryCenter = UnitPoint(
                x: 0.5 - cos(primaryAngle * 0.65 + .pi / 3) * 0.26,
                y: 0.5 - sin(primaryAngle * 0.55) * 0.28
            )

            GeometryReader { geometry in
                let beamRadius = max(geometry.size.width, geometry.size.height) * 0.62
                let secondaryIntensity = delayedIntensity(beamIntensity, delay: secondaryDelay)

                ZStack {
                    Color.appMainBackground

                    spotlightBeam(
                        center: primaryCenter,
                        radius: beamRadius,
                        intensity: beamIntensity,
                        core: Color.appAccent.opacity(0.38),
                        halo: Color.appSoftGold.opacity(0.14)
                    )

                    spotlightBeam(
                        center: secondaryCenter,
                        radius: beamRadius * 0.72,
                        intensity: secondaryIntensity,
                        core: Color.appText.opacity(0.1),
                        halo: Color.appAccent.opacity(0.08)
                    )
                    
                    spotlightBeam(
                        center: secondaryCenter,
                        radius: beamRadius * 0.72,
                        intensity: beamIntensity,
                        core: Color.appText.opacity(0.1),
                        halo: Color.appTopEvent.opacity(0.08)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: fadeInDuration)) {
                beamIntensity = 1
            }
        }
        .onChange(of: isExiting) { _, exiting in
            guard exiting else { return }
            withAnimation(.easeInOut(duration: 0.55)) {
                beamIntensity = 0
            }
        }
    }

    private func delayedIntensity(_ intensity: CGFloat, delay: TimeInterval) -> CGFloat {
        guard intensity > 0 else { return 0 }
        let threshold = CGFloat(delay / fadeInDuration)
        guard intensity > threshold else { return 0 }
        return min((intensity - threshold) / (1 - threshold), 1)
    }

    private func spotlightBeam(
        center: UnitPoint,
        radius: CGFloat,
        intensity: CGFloat,
        core: Color,
        halo: Color
    ) -> some View {
        RadialGradient(
            colors: [
                core.opacity(intensity),
                halo.opacity(intensity),
                .clear,
            ],
            center: center,
            startRadius: 0,
            endRadius: max(radius * intensity, 1)
        )
        .blendMode(.plusLighter)
    }
}

private struct LaunchLogoView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let breath = (sin(time * 1.1) + 1) / 2

            Image(ImageResource.logoBlackEng)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.appText)
                .scaleEffect(0.985 + breath * 0.03)
                .padding(.horizontal, 40)
        }
    }
}

private struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
