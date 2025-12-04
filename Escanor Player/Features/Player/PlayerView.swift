//
//  PlayerView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct PlayerView: View {
    let mediaItem: MediaItem
    @StateObject private var controller = PlayerController()
    @State private var showControls = true
    @State private var shouldIgnoreNextToggle = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            PlayerKitContainer(controller: controller)
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
            if controller.isBuffering {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView("Loading…")
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .foregroundStyle(.white)
                }
                .transition(.opacity)
            }
            if showControls {
                ControlsOverlay(
                    isPlaying: controller.isPlaying,
                    currentTime: controller.currentTime,
                    duration: controller.duration,
                    mediaTitle: mediaItem.titleGuess,
                    subtitle: nil,
                    onClose: { dismiss() },
                    onPlayPause: controller.togglePlayPause,
                    onSeek: controller.seek(to:),
                    onSeekRelative: controller.seek(by:),
                    onInteraction: registerControlInteraction
                )
                .transition(.opacity)
            }
        }
        .colorScheme(.dark)
        .task {
            if mediaItem.path.first == "/" {
                controller.playLocalFile(at: URL(fileURLWithPath: mediaItem.path))
            } else {
                controller.playLocalFile(at: URL(string: mediaItem.path) ?? URL(fileURLWithPath: mediaItem.path))
            }
        }
    }

    private func registerControlInteraction() {
        shouldIgnoreNextToggle = true
    }
}

//#Preview {
//    PlayerView(mediaItem: MediaItem(id: UUID(), path: "/path/to/media.mp4", titleGuess: "Sample Video", lastSeenAt: Date()))
//        .frame(height: 320)
//        .padding()
//        .background(Color.black)
//}
