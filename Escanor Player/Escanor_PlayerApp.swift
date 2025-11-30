//
//  Escanor_PlayerApp.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import SwiftData
import SQLiteData
import Dependencies

@main
struct Escanor_PlayerApp: App {
    init() {
        try! prepareDependencies {
            try $0.bootstrapDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(MediaScanner())
        }
    }
}
