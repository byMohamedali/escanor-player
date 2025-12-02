//
//  SourceBrowserView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import Foundation

struct SourceBrowserView: View {
    let source: RemoteSource
    let startPath: String
    let onNavigate: (String) -> Void

    @State private var items: [RemoteItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMediaItem: MediaItem?
    @State private var selectedItem: RemoteItem?

    private let videoExtensions: Set<String> = ItemFilter.videoExtensions

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            ForEach(items, id: \.path) { item in
                HStack {
                    Image(systemName: item.isDirectory ? "folder" : "film")
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text(item.name)
                        if let size = item.size, !item.isDirectory {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { handleTap(item) }
            }
        }
        .navigationTitle(titleForPath(startPath))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await load()
        }
        .sheet(item: $selectedMediaItem) { mediaItem in
            PlayerView(
                mediaItem: mediaItem
            )
                .ignoresSafeArea()
        }
        .sheet(item: $selectedItem) { item in
            RemoteItemDetailView(item: item)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await source.list(at: startPath)
            await MainActor.run {
                items = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func handleTap(_ item: RemoteItem) {
        if item.isDirectory {
            let next = pathByAppending(startPath, component: item.name)
            onNavigate(next)
        } else if isVideo(item) {
            Task {
                do {
                    let urlString = try await source.openFile(at: item.path)
                    await MainActor.run {
                        selectedMediaItem = MediaItem(
                            id: item.id.uuidString,
                            shareId: UUID(),
                            path: urlString,
                            size: item.size,
                            mtime: nil,
                            kind: .movie,
                            tmdbId: nil,
                            seriesTmdbId: nil,
                            episodeTmdbId: nil,
                            seasonNumber: nil,
                            episodeNumber: nil,
                            titleGuess: URL(string: urlString)?.lastPathComponent,
                            yearGuess: nil,
                            discoveredAt: nil,
                            lastSeenAt: nil
                        )
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            selectedItem = item
        }
    }

    private func isVideo(_ item: RemoteItem) -> Bool {
        let ext = (item.name as NSString).pathExtension.lowercased()
        return videoExtensions.contains(ext)
    }

    private func titleForPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.isEmpty ? source.displayName : trimmed
    }

    private func pathByAppending(_ base: String, component: String) -> String {
        var base = base
        if !base.hasSuffix("/") { base.append("/") }
        return base + component
    }
}

private struct RemoteItemDetailView: View {
    let item: RemoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name).font(.headline)
            Text(item.path).font(.caption)
            if let size = item.size {
                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
            }
            if let modified = item.modifiedAt {
                Text(modified.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
