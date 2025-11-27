//
//  ContentView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .library

    enum Tab: Hashable {
        case library
        case network
        case settings

        var label: some View {
            switch self {
            case .library:
                Label("Library", systemImage: "play.rectangle.on.rectangle")
            case .network:
                Label("Network", systemImage: "server.rack")
            case .settings:
                Label("Settings", systemImage: "gearshape")
            }
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            LibraryHomeView()
                .tabItem { Tab.library.label }
                .tag(Tab.library)

            NetworkHomeView()
                .tabItem { Tab.network.label }
                .tag(Tab.network)

            SettingsHomeView()
                .tabItem { Tab.settings.label }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
