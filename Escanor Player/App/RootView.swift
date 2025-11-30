//
//  RootView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import SwiftData
import Defaults

struct RootView: View {
    @State private var showingSplash = true
    @Default(.accentTheme) private var accentTheme
    @Environment(\.scenePhase) var scenePhase // 1
    @StateObject private var scanner = MediaScanner()

    var body: some View {
        ZStack {
            ContentView()
                .opacity(showingSplash ? 0 : 1)
                .animation(.easeInOut(duration: 0.45), value: showingSplash)

            if showingSplash {
                SplashScreenView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.2))
            await MainActor.run {
                withAnimation(.snappy(duration: 0.5)) {
                    showingSplash = false
                }
            }
        }
        .tint(accentTheme.color)
        .accentColor(accentTheme.color)
        .onChange(of: scenePhase) { oldPhase, newPhase in // 2
                   if newPhase == .active { // 3
                       print("App became active")
                       Task {
                           await scanner.scanAllShares()
                       }
                       // Perform actions when the app becomes active, e.g., refresh data, restart timers.
                   } else if newPhase == .inactive {
                       print("App became inactive")
                       // Perform actions when the app becomes inactive, e.g., pause tasks.
                   } else if newPhase == .background {
                       print("App moved to background")
                       // Perform actions when the app moves to the background, e.g., save data, reduce resource usage.
                   }
               }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Item.self, inMemory: true)
}
