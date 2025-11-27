//
//  PlayerView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct PlayerView: View {
    @StateObject private var controller = PlayerController()
    @State private var showControls = true
    @State private var shouldIgnoreNextToggle = false

    var body: some View {
        ZStack(alignment: .bottom) {
            PlayerKitContainer(controller: controller)

            if showControls {
                ControlsOverlay(
                    isPlaying: controller.isPlaying,
                    currentTime: controller.currentTime,
                    duration: controller.duration,
                    onPlayPause: controller.togglePlayPause,
                    onSeek: controller.seek(to:),
                    onInteraction: registerControlInteraction
                )
                .transition(.opacity)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 16)
        .task {
            controller.loadDemoIfNeeded()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !shouldIgnoreNextToggle else {
                shouldIgnoreNextToggle = false
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
    }

    private func registerControlInteraction() {
        shouldIgnoreNextToggle = true
    }
}

#Preview {
    PlayerView()
        .frame(height: 320)
        .padding()
        .background(Color.black)
}
