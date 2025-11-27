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
    let onPlayPause: () -> Void
    let onSeek: (TimeInterval) -> Void
    let onInteraction: () -> Void

    private var formattedTime: String {
        func format(_ time: TimeInterval) -> String {
            guard time.isFinite else { return "--:--" }
            let totalSeconds = Int(time)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
        return "\(format(currentTime)) / \(format(duration))"
    }

    var body: some View {
        VStack(spacing: 16) {
            if duration > 0 {
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
                .padding(.horizontal, 8)

                Text(formattedTime)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button(action: {
                onInteraction()
                onPlayPause()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(.black.opacity(0.4))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.75),
                    .black.opacity(0.2)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    ControlsOverlay(
        isPlaying: true,
        currentTime: 35,
        duration: 90,
        onPlayPause: {},
        onSeek: { _ in },
        onInteraction: {}
    )
    .background(.black)
}
