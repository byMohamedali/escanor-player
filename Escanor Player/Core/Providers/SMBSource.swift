//
//  SMBSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import AMSMB2

class SMBSource: RemoteSource {
    let serverHost: String
    let share: String
    let credential: URLCredential

    var displayName: String { "SMB \(serverHost)/\(share)" }

    private lazy var manager: SMB2Manager? = {
        guard let url = URL(string: "smb://\(serverHost)") else { return nil }
        return SMB2Manager(url: url, credential: credential)
    }()

    init(host: String, username: String?, password: String?) {
        let parts = host.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count == 2 {
            self.serverHost = String(parts[0])
            self.share = String(parts[1])
        } else {
            self.serverHost = host
            self.share = "share"
        }
        self.credential = URLCredential(user: username ?? "guest", password: password ?? "", persistence: .forSession)
    }

    private func connect() async throws -> SMB2Manager {
        guard let manager else {
            throw NSError(domain: "SMBSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid SMB URL"])
        }
        try await manager.connectShare(name: share)
        return manager
    }

    func list(at path: String) async throws -> [RemoteItem] {
        let client = try await connect()
        let remotePath = path.isEmpty ? "/" : path
        let entries = try await client.contentsOfDirectory(atPath: remotePath)
        return entries.compactMap { entry in
            guard
                let name = entry[.nameKey] as? String,
                let path = entry[.pathKey] as? String,
                let type = entry[.fileResourceTypeKey] as? URLFileResourceType
            else { return nil }

            let size = entry[.fileSizeKey] as? Int64
            let modified = entry[.contentModificationDateKey] as? Date
            return RemoteItem(
                path: path,
                name: name,
                isDirectory: type == .directory,
                size: size != nil ? Int(size!) : nil,
                modifiedAt: modified
            )
        }
    }

    func openFile(at path: String) async throws -> URL {
        let client = try await connect()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
//        try await client.copyItem(atPath: path)
        return URL(string: path)!
    }
}
