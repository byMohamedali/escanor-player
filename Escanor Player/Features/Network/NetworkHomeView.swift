//
//  NetworkHomeView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import SQLiteData
import Dependencies

struct NetworkHomeView: View {
    @FetchAll(SavedShareRecord.order(by: \.name)) private var shareRecords: [SavedShareRecord]
    @Dependency(\.defaultDatabase) private var database
    @State private var showingAddShare = false
    @StateObject private var scanner = MediaScanner()

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
    }
}

#Preview {
    NetworkHomeView()
}
