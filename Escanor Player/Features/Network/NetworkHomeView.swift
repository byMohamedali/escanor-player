//
//  NetworkHomeView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct NetworkHomeView: View {
    var body: some View {
        ContentPlaceholder(
            title: "Network Sources",
            message: "Add SMB, FTP, WebDAV, and cloud servers from here.",
            systemImage: "antenna.radiowaves.left.and.right"
        )
    }
}

#Preview {
    NetworkHomeView()
}
