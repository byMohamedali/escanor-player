//
//  WebDAVForm.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct WebDAVFormData {
    var name: String = ""
    var url: String = ""
    var username: String = ""
    var password: String = ""
}

struct WebDAVForm: View {
    @Binding var draft: WebDAVFormData
    @Binding var testResult: String?

    let onSave: (WebDAVFormData) -> Void
    let onTest: (WebDAVFormData) -> Void
    let onCancel: () -> Void

    var body: some View {
        Form {
            Section("Server") {
                TextField("Display name", text: $draft.name)
                TextField("Server URL (https://example.com/webdav)", text: $draft.url)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }

            Section("Credentials") {
                TextField("Username", text: $draft.username)
                SecureField("Password", text: $draft.password)
            }

            if let testResult {
                Section("Connection Test") {
                    Text(testResult)
                        .foregroundStyle(testResult.lowercased().contains("success") ? .green : .red)
                }
            }
        }
        .navigationTitle("Add WebDAV")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { onSave(draft) }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Test") { onTest(draft) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WebDAVForm(
            draft: .constant(WebDAVFormData()),
            testResult: .constant(nil),
            onSave: { _ in },
            onTest: { _ in },
            onCancel: {}
        )
    }
}
