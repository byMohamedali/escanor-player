//
//  LibraryHomeView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct LibraryHomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PlayerView()
                        .aspectRatio( 16 / 9, contentMode: .fill)

                    Text("This demo player is wired up to PlayerKit. We'll swap in your actual library videos soon.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryHomeView()
}
