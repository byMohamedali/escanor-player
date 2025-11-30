//
//  ControlsOverlay.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct ControlsOverlay: View {
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let mediaTitle: String?
    let subtitle: String?
    let onClose: (() -> Void)?
    let onPlayPause: () -> Void
    let onSeek: (TimeInterval) -> Void
    let onSeekRelative: (TimeInterval) -> Void
    let onInteraction: () -> Void

    private func format(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "--:--" }
        let totalSeconds = Int(time.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 16) {
            topBar

            Spacer()

            centerControls

            Spacer()

            if duration > 0 {
                GlassEffectContainer {
                    HStack(spacing: 12) {
                        Text(format(currentTime))
                            .foregroundStyle(.white.opacity(0.85))
                        Slider(
                            value: .init(
                                get: { currentTime },
                                set: {
                                    onInteraction()
                                    onSeek($0)
                                }
                            ),
                            in: 0...duration
                        )
                        .tint(.white)
                        Text("-\(format(max(duration - currentTime, 0)))")
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .font(.caption.monospacedDigit())
                    .padding()
                }
                .glassEffect()
                .padding()
            }

            if mediaTitle != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    if let mediaTitle {
                        Text(mediaTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//        .background(
//            LinearGradient(
//                colors: [
//                    .black.opacity(0.55),
//                    .black.opacity(0.2)
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .ignoresSafeArea()
//        )
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if let onClose {
                ControlPill(icon: "xmark") {
                    onInteraction()
                    onClose()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var centerControls: some View {
        HStack(spacing: 40) {
            ControlCircle(icon: "gobackward.10") {
                onInteraction()
                onSeekRelative(-10)
            }

            ControlCircle(icon: isPlaying ? "pause.fill" : "play.fill", size: 78) {
                onInteraction()
                onPlayPause()
            }

            ControlCircle(icon: "goforward.10") {
                onInteraction()
                onSeekRelative(10)
            }
        }
    }
}

private struct ControlCircle: View {
    let icon: String
    var size: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.system(size: size == 60 ? 22 : 28, weight: .semibold))
                .padding()
                .frame(width: size, height: size)
        }
        .buttonBorderShape(.circle)
        .buttonStyle(.glass)
    }
}

private struct ControlPill: View {
    let icon: String
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                if let label {
                    Text(label)
                        .font(.callout.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
    }
}
