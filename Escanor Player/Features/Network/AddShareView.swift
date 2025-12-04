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
import Network

struct AddShareView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.defaultDatabase) private var database
    @StateObject private var bonjourDiscovery = BonjourDiscovery()

    @State private var showingFolderPicker = false
    @State private var smbFormPresented = false
    @State private var ftpFormPresented = false
    @State private var webDAVFormPresented = false
    @State private var smbDraft = SMBFormData()
    @State private var ftpDraft = FTPFormData()
    @State private var webDAVDraft = WebDAVFormData()
    @State private var infoMessage: String?
    @State private var testResult: String?

    private let providers = ProviderKind.allCases

    var body: some View {
        List {
            if !bonjourDiscovery.services.isEmpty || bonjourDiscovery.isSearching {
                Section("Available Shares") {
//                    if bonjourDiscovery.isSearching {
//                        HStack {
//                            ProgressView()
//                            Text("Searching...")
//                        }
//                    }
                    ForEach(bonjourDiscovery.services) { service in
                        Button {
                            handleResolvedSMB(service)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .foregroundStyle(.primary)
                                    Text(service.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
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
        .onAppear {
            bonjourDiscovery.start()
        }
        .onDisappear {
            bonjourDiscovery.stop()
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
                    testResult: $testResult,
                    onSave: { draft in
                        Task { await saveSMB(draft: draft) }
                    },
                    onTest: { draft in
                        Task { await testOnly(draft: draft) }
                    },
                    onCancel: {
                        smbDraft = SMBFormData()
                        testResult = nil
                        dismiss()
                    }
                )
            }
        }
        .sheet(isPresented: $ftpFormPresented) {
            NavigationStack {
                FTPForm(
                    draft: $ftpDraft,
                    testResult: $testResult,
                    onSave: { draft in
                        Task { await saveFTP(draft: draft) }
                    },
                    onTest: { draft in
                        Task { await testFTP(draft: draft) }
                    },
                    onCancel: {
                        ftpDraft = FTPFormData()
                        testResult = nil
                        dismiss()
                    }
                )
            }
        }
        .sheet(isPresented: $webDAVFormPresented) {
            NavigationStack {
                WebDAVForm(
                    draft: $webDAVDraft,
                    testResult: $testResult,
                    onSave: { draft in
                        Task { await saveWebDAV(draft: draft) }
                    },
                    onTest: { draft in
                        Task { await testWebDAV(draft: draft) }
                    },
                    onCancel: {
                        webDAVDraft = WebDAVFormData()
                        testResult = nil
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
        case .ftp:
            ftpFormPresented = true
        case .webdav:
            webDAVFormPresented = true
        default:
            infoMessage = "\(provider.displayName) is planned for later."
        }
    }

    private func handleResolvedSMB(_ service: DiscoveredSMB) {
        smbDraft = SMBFormData(
            name: service.name,
            host: "\(service.host)",
            username: "",
            password: ""
        )
        smbFormPresented = true
    }

    private func providers(for category: ProviderCategory) -> [ProviderKind] {
        providers.filter { $0.category == category }
    }

    private func saveSMB(draft: SMBFormData) async {
        guard !draft.host.isEmpty else {
            infoMessage = "Host is required to save SMB share."
            return
        }

        let (connected, error) = await testSMBConnection(draft: draft)
        if connected {
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
        } else {
            infoMessage = error ?? "Could not connect to SMB share."
        }
    }

    private func saveFTP(draft: FTPFormData) async {
        guard !draft.host.isEmpty else {
            infoMessage = "Host is required to save FTP share."
            return
        }

        let (connected, error) = await testFTPConnection(draft: draft)
        if connected {
            let share = SavedShare(
                name: draft.name.isEmpty ? draft.host : draft.name,
                kind: .ftp(
                    host: draft.host,
                    port: draft.portNumber,
                    username: draft.username.isEmpty ? nil : draft.username,
                    password: draft.password.isEmpty ? nil : draft.password,
                    passive: draft.passive
                )
            )
            persistAndDismiss(share)
            ftpDraft = FTPFormData()
        } else {
            infoMessage = error ?? "Could not connect to FTP server."
        }
    }

    private func testFTP(draft: FTPFormData) async {
        let (ok, error) = await testFTPConnection(draft: draft)
        await MainActor.run {
            testResult = ok ? "Connection successful" : (error ?? "Connection failed")
        }
    }

    private func testFTPConnection(draft: FTPFormData) async -> (Bool, String?) {
        let source = FTPSource(
            host: draft.host,
            port: draft.portNumber,
            username: draft.username.isEmpty ? nil : draft.username,
            password: draft.password.isEmpty ? nil : draft.password,
            passive: draft.passive
        )
        do {
            _ = try await source.list(at: "/")
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func testSMBConnection(draft: SMBFormData) async -> (Bool, String?) {
        let source = SMBSource(host: draft.host, username: draft.username.isEmpty ? nil : draft.username, password: draft.password)
        do {
            _ = try await source.list(at: "/")
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func testOnly(draft: SMBFormData) async {
        let (ok, error) = await testSMBConnection(draft: draft)
        await MainActor.run {
            testResult = ok ? "Connection successful" : (error ?? "Connection failed")
        }
    }

    private func testWebDAV(draft: WebDAVFormData) async {
        let (ok, error) = await testWebDAVConnection(draft: draft)
        await MainActor.run {
            testResult = ok ? "Connection successful" : (error ?? "Connection failed")
        }
    }

    private func testWebDAVConnection(draft: WebDAVFormData) async -> (Bool, String?) {
        guard let url = URL(string: draft.url) else {
            return (false, "Invalid URL")
        }
        guard let source = WebDAVSource(url: url, username: draft.username.isEmpty ? nil : draft.username, password: draft.password.isEmpty ? nil : draft.password) else {
            return (false, "Invalid server configuration")
        }
        do {
            _ = try await source.list(at: "/")
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func saveWebDAV(draft: WebDAVFormData) async {
        guard let url = URL(string: draft.url) else {
            infoMessage = "Invalid URL"
            return
        }
        let (connected, error) = await testWebDAVConnection(draft: draft)
        if connected {
            let share = SavedShare(
                name: draft.name.isEmpty ? (url.host ?? "WebDAV") : draft.name,
                kind: .webdav(
                    url: url,
                    username: draft.username.isEmpty ? nil : draft.username,
                    password: draft.password.isEmpty ? nil : draft.password
                )
            )
            persistAndDismiss(share)
            webDAVDraft = WebDAVFormData()
        } else {
            infoMessage = error ?? "Could not connect to WebDAV server."
        }
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
    @Binding var testResult: String?
    let onSave: (SMBFormData) -> Void
    let onTest: (SMBFormData) -> Void
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

            Section {
                Button("Test Connection") {
                    onTest(draft)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                if let testResult {
                    Text(testResult)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
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
