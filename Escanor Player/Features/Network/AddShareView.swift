//
//  AddShareView.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Dependencies
import SQLiteData

struct AddShareView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.defaultDatabase) private var database

    @State private var showingFolderPicker = false
    @State private var smbFormPresented = false
    @State private var smbDraft = SMBFormData()
    @State private var infoMessage: String?

    private let providers = ProviderKind.allCases

    var body: some View {
        List {
            ForEach(ProviderCategory.allCases) { category in
                Section(category.title) {
                    ForEach(providers(for: category)) { provider in
                        AddShareRow(provider: provider) {
                            handle(provider)
                        }
                    }
                }
            }
        }
        .navigationTitle("Add Share")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                _ = url.startAccessingSecurityScopedResource()
                let bookmark = try? url.bookmarkData()
                persistAndDismiss(
                    SavedShare(name: url.lastPathComponent, kind: .localFolder(url: url, bookmark: bookmark))
                )
            case .failure(let error):
                infoMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $smbFormPresented) {
            NavigationStack {
                SMBForm(
                    draft: $smbDraft,
                    onSave: { draft in
                        guard !draft.host.isEmpty else {
                            infoMessage = "Host is required to save SMB share."
                            return
                        }
                        let share = SavedShare(
                            name: draft.name.isEmpty ? draft.host : draft.name,
                            kind: .smb(
                                host: draft.host,
                                username: draft.username.isEmpty ? nil : draft.username,
                                password: draft.password.isEmpty ? nil : draft.password
                            )
                        )
                        persistAndDismiss(share)
                        smbDraft = SMBFormData()
                    },
                    onCancel: {
                        smbDraft = SMBFormData()
                        dismiss()
                    }
                )
            }
        }
        .alert("Notice", isPresented: Binding(get: { infoMessage != nil }, set: { newValue in
            if !newValue { infoMessage = nil }
        })) {
            Button("OK", role: .cancel) { infoMessage = nil }
        } message: {
            Text(infoMessage ?? "")
        }
    }

    private func handle(_ provider: ProviderKind) {
        switch provider {
        case .localFolder:
            showingFolderPicker = true
        case .smb:
            smbFormPresented = true
        default:
            infoMessage = "\(provider.displayName) is planned for later."
        }
    }

    private func providers(for category: ProviderCategory) -> [ProviderKind] {
        providers.filter { $0.category == category }
    }

    private func persistAndDismiss(_ share: SavedShare) {
        do {
            let draft = try SavedShareRecord.draft(from: share)
            try database.write { db in
                try SavedShareRecord.insert { draft }.execute(db)
            }
            dismiss()
        } catch {
#if DEBUG
            print("Failed to save share: \(error)")
#endif
            infoMessage = "Failed to save share. Please try again."
        }
    }
}

// MARK: - SMB Form

private struct AddShareRow: View {
    let provider: ProviderKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: provider.systemImage)
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .foregroundStyle(.primary)
                    if !provider.isImplementedInMVP {
                        Text("Coming soon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if provider.isImplementedInMVP {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(!provider.isImplementedInMVP)
        .opacity(provider.isImplementedInMVP ? 1 : 0.4)
    }
}

private struct SMBFormData {
    var name: String = ""
    var host: String = ""
    var username: String = ""
    var password: String = ""
}

private struct SMBForm: View {
    @Binding var draft: SMBFormData
    let onSave: (SMBFormData) -> Void
    let onCancel: () -> Void

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Name (optional)", text: $draft.name)
                    .textContentType(.nickname)
                TextField("Host", text: $draft.host)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                TextField("Username", text: $draft.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                SecureField("Password", text: $draft.password)
                    .textContentType(.password)
            }
        }
        .navigationTitle("Add SMB")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(draft)
                }
                .disabled(draft.host.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddShareView()
    }
}
