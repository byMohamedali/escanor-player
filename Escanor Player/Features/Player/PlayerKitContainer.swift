//
//  PlayerKitContainer.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import PlayerKit

#if canImport(UIKit)
struct PlayerKitContainer: UIViewRepresentable {
    @ObservedObject var controller: PlayerController

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        controller.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        controller.layout(in: uiView)
    }
}
#else
struct PlayerKitContainer: NSViewRepresentable {
    @ObservedObject var controller: PlayerController

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        controller.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        controller.layout(in: nsView)
    }
}
#endif
