//
//  FTPForm.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import SwiftUI

struct FTPFormData {
    var name: String = ""
    var host: String = ""
    var port: String = "21"
    var username: String = ""
    var password: String = ""
    var passive: Bool = true

    var portNumber: Int {
        Int(port) ?? 21
    }
}

struct FTPForm: View {
    @Binding var draft: FTPFormData
    @Binding var testResult: String?

    let onSave: (FTPFormData) -> Void
    let onTest: (FTPFormData) -> Void
    let onCancel: () -> Void

    var body: some View {
        Form {
            Section("Server") {
                TextField("Display name", text: $draft.name)
                TextField("Host", text: $draft.host)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("21", text: $draft.port)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Toggle("Passive mode", isOn: $draft.passive)
            }

            Section("Credentials") {
                TextField("Username (optional)", text: $draft.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $draft.password)
                    .textContentType(.password)
            }

            if let testResult {
                Section("Connection Test") {
                    Text(testResult)
                        .foregroundStyle(testResult.lowercased().contains("success") ? .green : .red)
                }
            }
        }
        .navigationTitle("Add FTP")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { onSave(draft) }
                    .disabled(draft.host.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Test") { onTest(draft) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FTPForm(
            draft: .constant(FTPFormData()),
            testResult: .constant(nil),
            onSave: { _ in },
            onTest: { _ in },
            onCancel: {}
        )
    }
}
