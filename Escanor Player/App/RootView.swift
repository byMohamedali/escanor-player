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
    }
}

#Preview {
    RootView()
        .modelContainer(for: Item.self, inMemory: true)
}
