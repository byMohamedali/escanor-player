//
//  SMBSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation

/// Minimal SMB adapter. Replace stubbed calls with a concrete SMB client (e.g. libsmb2).
struct SMBSource: RemoteSource {
    let host: String
    let username: String?
    let password: String?

    var displayName: String { "SMB \(host)" }

    func list(at path: String) async throws -> [RemoteItem] {
        // TODO: Integrate SMB client. For now, return empty to keep app compiling.
        return []
    }

    func openFile(at path: String) async throws -> URL {
        // TODO: Download to temp file or stream if supported by PlayerKit.
        throw NSError(domain: "SMBSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "SMB streaming not implemented yet."])
    }
}

