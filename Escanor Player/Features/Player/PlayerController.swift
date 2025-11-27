//
//  PlayerController.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import Combine
import PlayerKit
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PlayerController: ObservableObject {
    enum PlayerSource {
        case remote(URL)
    }

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = .zero
    @Published private(set) var duration: TimeInterval = .zero

    let player: EscanorPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedSource = false

    init() {
        self.player = try? EscanorPlayer()
        listenToEvents()
    }

    func attach(to view: PlatformView) {
        player?.plugViewToPlayer(view: view)
    }

    func layout(in view: PlatformView) {
        player?.layoutSubviews(in: view)
    }

    func loadDemoIfNeeded() {
        guard !hasLoadedSource, let url = Self.demoURL else { return }
        player?.play(with: url)
        hasLoadedSource = true
    }

    func togglePlayPause() {
        player?.playOrPause()
    }

    func seek(to time: TimeInterval) {
        currentTime = time
        player?.seek(to: time)
    }

    private func listenToEvents() {
        player?.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .started(_):
                    self.isPlaying = true
                case .ready:
                    self.duration = self.player?.duration ?? self.duration
                case .paused:
                    self.isPlaying = false
                case .resumed:
                    self.isPlaying = true
                    self.isPlaying = true
                case .ready:
                    self.duration = self.player?.duration ?? self.duration
                case .paused:
                    self.isPlaying = false
                case .resumed:
                    self.isPlaying = true
                case .completed:
                    self.isPlaying = false
                    self.currentTime = self.duration
                case .timeUpdated(let time):
                    self.currentTime = time
                case .durationUpdated(let duration):
                    self.duration = duration
                case .buffering(_):
                    break
                case .stopped:
                    self.isPlaying = false
                case .error(_):
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }
}

extension PlayerController {
    static var demoURL: URL? {
//        URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/gear4/prog_index.m3u8")
        URL(string: "https://t6u7v8.debrid.it/dl/45xunq411e2/%5BCommunity%5D%20Magi%20-%20The%20Labyrinth%20of%20Magic%20-%2001%20%5BMulti%20BDrip%201080p%20x265%5D.mkv")
    }
}
