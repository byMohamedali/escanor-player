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
    @EnvironmentObject private var scanner: MediaScanner
    @State private var selectedItem: MediaItem?

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    ForEach(items) { item in
                        MediaCard(item: item)
                            .onTapGesture {
                                Task {
                                    await requestAccessAndPlay(item)
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await scanner.scanAllShares() }
                    } label: {
                        if scanner.isScanning {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedItem) { item in
            PlayerView(mediaItem: item)
                .ignoresSafeArea()
        }
    }

    private func requestAccessAndPlay(_ item: MediaItem) async {
        do {
            let share = try await database.read { db in
                try SavedShareRecord.find(item.shareId).fetchOne(db)
            }
            guard let share, let kind = share.kind else { return }

            switch kind {
            case .localFolder(let url, let bookmark):
                var resolvedURL: URL? = url
                var stale: Bool = false
                if let bookmark {
                    resolvedURL = try? URL(resolvingBookmarkData: bookmark, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
                }

                guard let target = resolvedURL else { return }
                let granted = target.startAccessingSecurityScopedResource()
                if granted || FileManager.default.isReadableFile(atPath: target.path) {
                    var newItem = item
                    let filename = URL(filePath: item.path).lastPathComponent
                    newItem.path = target.path() + filename
                    selectedItem = newItem
                } else {
#if DEBUG
                    print("Access denied for \(target)")
#endif
                }

            default:
                selectedItem = item
            }
        } catch {
#if DEBUG
            print("Failed to resolve share for playback: \(error)")
#endif
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
