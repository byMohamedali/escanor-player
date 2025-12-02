//
//  SplashScreenView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowPulse = false
    @State private var emblemBounce = false

    var body: some View {
        ZStack {
            backgroundLayer
            accentParticles

            VStack(spacing: 24) {
                logoCard
                titleBlock
            }
            .padding(32)
        }
        .task {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.snappy(duration: 1.2, extraBounce: 0.18).repeatForever(autoreverses: true)) {
                emblemBounce = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Escanor Player loading")
        .accessibilityHint("Preparing your cinematic library")
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color.obsidian,
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.15, green: 0.12, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [Color.escanorGold.opacity(0.35), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .blendMode(.screen)
        )
        .ignoresSafeArea()
    }

    private var accentParticles: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 220)
                .blur(radius: 50)
                .offset(x: -120, y: -240)
                .opacity(0.4)

            Circle()
                .fill(Color.escanorGold.opacity(0.35))
                .frame(width: 180)
                .blur(radius: glowPulse ? 38 : 18)
                .offset(x: 120, y: 200)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)
        }
        .allowsHitTesting(false)
    }

    private var logoCard: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.escanorGold.opacity(glowPulse ? 0.9 : 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                    .shadow(color: .black.opacity(0.4), radius: 22, y: 18)
                    .blendMode(.overlay)
            )
            .frame(width: 220, height: 220)
            .overlay {
                Image("logo")
                    .resizable()
                    .frame(width: 180, height: 180)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.emberGlow, Color.escanorGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.escanorGold.opacity(0.5), radius: glowPulse ? 28 : 8)
                    .scaleEffect(emblemBounce ? 1.05 : 0.95)
                    .animation(.snappy(duration: 1.4).repeatForever(autoreverses: true), value: emblemBounce)
                    .accessibilityHidden(true)
            }
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Escanor Player+")
                .font(.system(.title, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .tracking(0.6)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)

            Text("A calm, glassy, cinematic home for your media.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SplashScreenView()
}
