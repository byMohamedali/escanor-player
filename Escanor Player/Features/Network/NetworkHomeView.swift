//
//  NetworkHomeView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import SQLiteData
import Dependencies


extension String: @retroactive Identifiable {
    public var id: String {
        self
    }
}

struct NetworkHomeView: View {
    @FetchAll(SavedShareRecord.order(by: \.name)) private var shareRecords: [SavedShareRecord]
    @Dependency(\.defaultDatabase) private var database
    @EnvironmentObject private var scanner: MediaScanner
    @State private var showingAddShare = false
    @State private var browsePath: [BrowseDestination] = []

    private var shares: [SavedShare] {
        shareRecords.compactMap { $0.toDomain() }
    }

    var body: some View {
        NavigationStack(path: $browsePath) {
            List {
                Section("Saved Shares") {
                    if shares.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No shares yet")
                                .font(.headline)
                            Text("Add a local folder or SMB server to get started.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                            .padding(.vertical, 8)
                    } else {
                        ForEach(shares) { share in
                            shareRow(share)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Network")
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddShare = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: BrowseDestination.self) { destination in
                if let source = buildSource(from: destination.share) {
                    SourceBrowserView(source: source, startPath: destination.path) { next in
                        browsePath.append(.init(share: destination.share, path: next))
                    }
                } else {
                    Text("Unsupported source")
                }
            }

        }
            .sheet(isPresented: $showingAddShare) {
                NavigationStack {
                    AddShareView()
                }
            }
            .task {
                await scanner.scanAllShares()
            }
    }

    private func delete(at indices: IndexSet) {
        let idsToDelete = indices.compactMap { shares[$0].id }
        do {
            try database.write { db in
                for id in idsToDelete {
                    try SavedShareRecord.find(id).delete().execute(db)
                }
            }
        } catch {
#if DEBUG
            print("Failed to delete shares: \(error)")
#endif
        }
    }

    private func shareRow(_ share: SavedShare) -> some View {
        let provider = share.kind.providerKind
        return NavigationLink(value: BrowseDestination(share: share, path: "/")) {
            HStack(spacing: 12) {
                Image(systemName: provider.systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(share.name)
                        .font(.headline)
                    Text(share.kind.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func buildSource(from share: SavedShare) -> RemoteSource? {
        switch share.kind {
        case .localFolder(let url, let bookmark):
            return LocalSource(root: url, bookmarkData: bookmark)
        case .smb(let host, let username, let password):
            return SMBSource(host: host, username: username, password: password)
        default:
            return nil
        }
    }
}

#Preview {
    NetworkHomeView()
}

private struct BrowseDestination: Hashable {
    let share: SavedShare
    let path: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(share.id)
        hasher.combine(path)
    }

    static func == (lhs: BrowseDestination, rhs: BrowseDestination) -> Bool {
        lhs.share.id == rhs.share.id && lhs.path == rhs.path
    }
}
