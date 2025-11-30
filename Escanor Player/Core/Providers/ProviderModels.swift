//
//  ProviderModels.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import SQLiteData
import GRDB

// MARK: - Provider Lists

enum ProviderCategory: String, CaseIterable, Identifiable {
    case local
    case network
    case cloud
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .local: return "Local Shares"
        case .network: return "Network Shares"
        case .cloud: return "Cloud Services"
        case .other: return "Other"
        }
    }
}

enum ProviderKind: String, CaseIterable, Identifiable, Codable {
    case localFolder
    case smb
    case ftp
    case nfs
    case webdav
    case googleDrive
    case dropbox
    case oneDrive
    case box
    case directURL
    case browser
    case usbCable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .localFolder: return "Add Local Folder"
        case .smb:         return "Add SMB"
        case .ftp:         return "Add FTP"
        case .nfs:         return "Add NFS"
        case .webdav:      return "Add WebDAV"
        case .googleDrive: return "Add Google Drive"
        case .dropbox:     return "Add Dropbox"
        case .oneDrive:    return "Add OneDrive"
        case .box:         return "Add Box"
        case .directURL:   return "Direct URL"
        case .browser:     return "Browser"
        case .usbCable:    return "USB Cable"
        }
    }

    var category: ProviderCategory {
        switch self {
        case .localFolder: return .local
        case .smb, .ftp, .nfs, .webdav: return .network
        case .googleDrive, .dropbox, .oneDrive, .box: return .cloud
        case .directURL, .browser, .usbCable: return .other
        }
    }

    var systemImage: String {
        switch self {
        case .localFolder: return "folder"
        case .smb:         return "server.rack"
        case .ftp:         return "arrow.up.arrow.down.circle"
        case .nfs:         return "square.stack.3d.down.forward"
        case .webdav:      return "externaldrive"
        case .googleDrive: return "triangle"
        case .dropbox:     return "shippingbox"
        case .oneDrive:    return "cloud"
        case .box:         return "cube.box"
        case .directURL:   return "link"
        case .browser:     return "safari"
        case .usbCable:    return "cable.connector"
        }
    }

    var isImplementedInMVP: Bool {
        switch self {
        case .localFolder, .smb:
            return true
        default:
            return false
        }
    }
}

// MARK: - Saved Shares

struct SavedShare: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var kind: SavedShareKind
    var lastAccess: Date?

    init(id: UUID = UUID(), name: String, kind: SavedShareKind, lastAccess: Date? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.lastAccess = lastAccess
    }
}

enum SavedShareKind: Codable, Equatable {
    case localFolder(url: URL)
    case smb(host: String, username: String?, password: String?)
    case ftp(host: String)
    case nfs(host: String)
    case webdav(url: URL)
    case googleDrive(accountID: String)
    case dropbox(accountID: String)
    case oneDrive(accountID: String)
    case box(accountID: String)
    case directURL(url: URL)

    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    private enum Kind: String, Codable {
        case localFolder, smb, ftp, nfs, webdav, googleDrive, dropbox, oneDrive, box, directURL
    }

    private struct SMBPayload: Codable {
        let host: String
        let username: String?
        let password: String?
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .localFolder(let url):
            try container.encode(Kind.localFolder, forKey: .type)
            try container.encode(url, forKey: .payload)
        case .smb(let host, let username, let password):
            try container.encode(Kind.smb, forKey: .type)
            try container.encode(SMBPayload(host: host, username: username, password: password), forKey: .payload)
        case .ftp(let host):
            try container.encode(Kind.ftp, forKey: .type)
            try container.encode(host, forKey: .payload)
        case .nfs(let host):
            try container.encode(Kind.nfs, forKey: .type)
            try container.encode(host, forKey: .payload)
        case .webdav(let url):
            try container.encode(Kind.webdav, forKey: .type)
            try container.encode(url, forKey: .payload)
        case .googleDrive(let accountID):
            try container.encode(Kind.googleDrive, forKey: .type)
            try container.encode(accountID, forKey: .payload)
        case .dropbox(let accountID):
            try container.encode(Kind.dropbox, forKey: .type)
            try container.encode(accountID, forKey: .payload)
        case .oneDrive(let accountID):
            try container.encode(Kind.oneDrive, forKey: .type)
            try container.encode(accountID, forKey: .payload)
        case .box(let accountID):
            try container.encode(Kind.box, forKey: .type)
            try container.encode(accountID, forKey: .payload)
        case .directURL(let url):
            try container.encode(Kind.directURL, forKey: .type)
            try container.encode(url, forKey: .payload)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Kind.self, forKey: .type)
        switch type {
        case .localFolder:
            let url = try container.decode(URL.self, forKey: .payload)
            self = .localFolder(url: url)
        case .smb:
            let payload = try container.decode(SMBPayload.self, forKey: .payload)
            self = .smb(host: payload.host, username: payload.username, password: payload.password)
        case .ftp:
            let host = try container.decode(String.self, forKey: .payload)
            self = .ftp(host: host)
        case .nfs:
            let host = try container.decode(String.self, forKey: .payload)
            self = .nfs(host: host)
        case .webdav:
            let url = try container.decode(URL.self, forKey: .payload)
            self = .webdav(url: url)
        case .googleDrive:
            let accountID = try container.decode(String.self, forKey: .payload)
            self = .googleDrive(accountID: accountID)
        case .dropbox:
            let accountID = try container.decode(String.self, forKey: .payload)
            self = .dropbox(accountID: accountID)
        case .oneDrive:
            let accountID = try container.decode(String.self, forKey: .payload)
            self = .oneDrive(accountID: accountID)
        case .box:
            let accountID = try container.decode(String.self, forKey: .payload)
            self = .box(accountID: accountID)
        case .directURL:
            let url = try container.decode(URL.self, forKey: .payload)
            self = .directURL(url: url)
        }
    }

    var providerKind: ProviderKind {
        switch self {
        case .localFolder: return .localFolder
        case .smb: return .smb
        case .ftp: return .ftp
        case .nfs: return .nfs
        case .webdav: return .webdav
        case .googleDrive: return .googleDrive
        case .dropbox: return .dropbox
        case .oneDrive: return .oneDrive
        case .box: return .box
        case .directURL: return .directURL
        }
    }

    var subtitle: String {
        switch self {
        case .localFolder(let url):
            return url.lastPathComponent
        case .smb(let host, _, _):
            return host
        case .ftp(let host):
            return host
        case .nfs(let host):
            return host
        case .webdav(let url):
            return url.host ?? url.absoluteString
        case .googleDrive(let accountID),
             .dropbox(let accountID),
             .oneDrive(let accountID),
             .box(let accountID):
            return accountID
        case .directURL(let url):
            return url.absoluteString
        }
    }
}

// MARK: - Persistence Bridge

@Table
nonisolated struct SavedShareRecord: Identifiable {
    static let databaseTableName = "savedShareRecords"

    let id: UUID
    var name: String
    var kindData: Data
    var lastAccess: Date?

    init?(id: UUID = UUID(), name: String, kind: SavedShareKind, lastAccess: Date? = nil) {
        guard let data = try? savedShareEncoder.encode(kind) else { return nil }
        self.id = id
        self.name = name
        self.kindData = data
        self.lastAccess = lastAccess
    }
}

private let savedShareEncoder = JSONEncoder()
private let savedShareDecoder = JSONDecoder()

extension SavedShareRecord {
    func toDomain() -> SavedShare? {
        guard let kind = try? savedShareDecoder.decode(SavedShareKind.self, from: kindData) else {
            return nil
        }
        return SavedShare(id: id, name: name, kind: kind, lastAccess: lastAccess)
    }

    static func draft(from share: SavedShare) throws -> Draft {
        let data = try savedShareEncoder.encode(share.kind)
        return Draft(
            id: share.id,
            name: share.name,
            kindData: data,
            lastAccess: share.lastAccess
        )
    }

    static func migrate(db: Database) throws {
        try #sql(
            """
            CREATE TABLE "savedShareRecords" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                "kindData" BLOB NOT NULL,
                "lastAccess" REAL
            ) STRICT
            """
        )
        .execute(db)
    }
}
