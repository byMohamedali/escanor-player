//
//  UserPreferences.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import Defaults

// MARK: - Accent Theme

enum AccentTheme: String, CaseIterable, Defaults.Serializable, Identifiable {
    case gold
    case ember
    case slate

    var id: Self { self }

    var displayName: String {
        switch self {
        case .gold: return "Escanor Gold"
        case .ember: return "Amber Ember"
        case .slate: return "Midnight Slate"
        }
    }

    var color: Color {
        switch self {
        case .gold: return Color(hex: 0xF2B263)
        case .ember: return Color(hex: 0xE0813D)
        case .slate: return Color(hex: 0x6F7D91)
        }
    }
}

extension Defaults.Keys {
    static let accentTheme = Key<AccentTheme>("accentTheme") { .gold }
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex & 0xFF0000) >> 16) / 255
        let green = Double((hex & 0x00FF00) >> 8) / 255
        let blue = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
