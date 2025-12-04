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
        case .localFolder, .smb, .ftp, .webdav:
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
    var includePaths: [String]?

    init(id: UUID = UUID(), name: String, kind: SavedShareKind, lastAccess: Date? = nil, includePaths: [String]? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.lastAccess = lastAccess
        self.includePaths = includePaths
    }
}

enum SavedShareKind: Codable, Equatable {
    case localFolder(url: URL, bookmark: Data?)
    case smb(host: String, username: String?, password: String?)
    case ftp(host: String, port: Int?, username: String?, password: String?, passive: Bool?)
    case nfs(host: String)
    case webdav(url: URL, username: String?, password: String?)
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

    private struct FTPPayload: Codable {
        let host: String
        let port: Int?
        let username: String?
        let password: String?
        let passive: Bool?
    }

    private struct LocalFolderPayload: Codable {
        let url: URL
        let bookmarkData: Data?
    }
    
    private struct WebDAVPayload: Codable {
        let url: URL
        let username: String?
        let password: String?
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .localFolder(let url, let bookmark):
            try container.encode(Kind.localFolder, forKey: .type)
            try container.encode(LocalFolderPayload(url: url, bookmarkData: bookmark), forKey: .payload)
        case .smb(let host, let username, let password):
            try container.encode(Kind.smb, forKey: .type)
            try container.encode(SMBPayload(host: host, username: username, password: password), forKey: .payload)
        case .ftp(let host, let port, let username, let password, let passive):
            try container.encode(Kind.ftp, forKey: .type)
            try container.encode(FTPPayload(host: host, port: port, username: username, password: password, passive: passive), forKey: .payload)
        case .nfs(let host):
            try container.encode(Kind.nfs, forKey: .type)
            try container.encode(host, forKey: .payload)
        case .webdav(let url, let username, let password):
            try container.encode(Kind.webdav, forKey: .type)
            try container.encode(WebDAVPayload(url: url, username: username, password: password), forKey: .payload)
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
            if let payload = try? container.decode(LocalFolderPayload.self, forKey: .payload) {
                self = .localFolder(url: payload.url, bookmark: payload.bookmarkData)
            } else {
                // Backward compatibility: payload was a URL only
                let url = try container.decode(URL.self, forKey: .payload)
                self = .localFolder(url: url, bookmark: nil)
            }
        case .smb:
            let payload = try container.decode(SMBPayload.self, forKey: .payload)
            self = .smb(host: payload.host, username: payload.username, password: payload.password)
        case .ftp:
            if let payload = try? container.decode(FTPPayload.self, forKey: .payload) {
                self = .ftp(host: payload.host, port: payload.port, username: payload.username, password: payload.password, passive: payload.passive)
            } else {
                let host = try container.decode(String.self, forKey: .payload)
                self = .ftp(host: host, port: nil, username: nil, password: nil, passive: nil)
            }
        case .nfs:
            let host = try container.decode(String.self, forKey: .payload)
            self = .nfs(host: host)
        case .webdav:
            if let payload = try? container.decode(WebDAVPayload.self, forKey: .payload) {
                self = .webdav(url: payload.url, username: payload.username, password: payload.password)
            } else {
                // Backward compatibility: payload was a URL only
                let url = try container.decode(URL.self, forKey: .payload)
                self = .webdav(url: url, username: nil, password: nil)
            }
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
        case .localFolder(let url, _):
            return url.lastPathComponent
        case .smb(let host, _, _):
            return host
        case .ftp(let host, let port, _, _, _):
            if let port, port != 21 {
                return "\(host):\(port)"
            }
            return host
        case .nfs(let host):
            return host
        case .webdav(let url, _, _):
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
    var kindData: Data?
    var lastAccess: Date?
    var includePathsData: Data?

    init?(id: UUID = UUID(), name: String, kind: SavedShareKind, lastAccess: Date? = nil, includePaths: [String]? = nil) {
        let data = try? savedShareEncoder.encode(kind)
        self.id = id
        self.name = name
        self.kindData = data
        self.lastAccess = lastAccess
        if let includePaths {
            self.includePathsData = try? JSONEncoder().encode(includePaths)
        }
    }
}

private let savedShareEncoder = JSONEncoder()
private let savedShareDecoder = JSONDecoder()

extension SavedShareRecord {
    var kind: SavedShareKind? {
        guard let kindData else { return nil }
        return try? savedShareDecoder.decode(SavedShareKind.self, from: kindData)
    }

    func toDomain() -> SavedShare? {
        guard let kind else { return nil }
        let paths = includePathsData.flatMap { try? JSONDecoder().decode([String].self, from: $0) }
        return SavedShare(id: id, name: name, kind: kind, lastAccess: lastAccess, includePaths: paths)
    }

    static func draft(from share: SavedShare) throws -> Draft {
        let data = try savedShareEncoder.encode(share.kind)
        return Draft(
            id: share.id,
            name: share.name,
            kindData: data,
            lastAccess: share.lastAccess,
            includePathsData: share.includePaths != nil ? try? JSONEncoder().encode(share.includePaths) : nil
        )
    }

    static func migrate(db: Database) throws {
        try db.create(table: "savedShareRecords") { t in
            t.primaryKey("id", .text)
            t.column("name", .text)
            t.column("kindData", .blob)
            t.column("lastAccess", .double)
            t.column("includePathsData", .blob)
        }
    }
}
