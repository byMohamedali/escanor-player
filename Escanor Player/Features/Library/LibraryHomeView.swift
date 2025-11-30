//
//  LibraryHomeView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import SQLiteData
import Dependencies

struct LibraryHomeView: View {
    @FetchAll(MediaItem.order(by: \.lastSeenAt)) private var items: [MediaItem]
    @Dependency(\.defaultDatabase) private var database

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    ForEach(items) { item in
                        MediaCard(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
        }
    }
}

private struct MediaCard: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 10)

                // Placeholder art for now
                VStack {
                    Image(systemName: "film")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.escanorGold)
                    Text(item.titleGuess ?? "Unknown title")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                }
                .padding(12)
            }
            .frame(height: 200)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.titleGuess ?? "Unknown title")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let year = item.yearGuess {
                    Text("\(year)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(item.kind == .tvEpisode ? "1 Season" : "Movie")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    LibraryHomeView()
}
