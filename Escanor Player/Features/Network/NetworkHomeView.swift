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
    @State private var selectedShare: SavedShare?
    @State private var browserPath: String?

    private var shares: [SavedShare] {
        shareRecords.compactMap { $0.toDomain() }
    }

    var body: some View {
        NavigationStack {
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
        }
            .sheet(isPresented: $showingAddShare) {
                NavigationStack {
                    AddShareView()
                }
            }
            .sheet(item: $browserPath) { path in
                if let share = selectedShare, let source = buildSource(from: share) {
                    NavigationStack {
                        SourceBrowserView(source: source, startPath: path) { next in
                            browserPath = next
                        }
                    }
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
        return HStack(spacing: 12) {
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
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedShare = share
            browserPath = "/"
        }
    }

    private func buildSource(from share: SavedShare) -> RemoteSource? {
        switch share.kind {
        case .localFolder(let url, _):
            return LocalSource(root: url)
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
