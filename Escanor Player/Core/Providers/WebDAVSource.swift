//
//  WebDAVSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import WebDavKit

final class WebDAVSource: RemoteSource {
    private let client: WebDAV
    private let filter: ItemFilter
    private let hostDisplay: String
    private let baseURL: URL
    private let username: String?
    private let password: String?

    var displayName: String { hostDisplay }

    init?(url: URL, username: String? = nil, password: String? = nil, filter: ItemFilter = .videoAndDirectories) {
        let port: Int
        if let explicitPort = url.port {
            port = explicitPort
        } else if url.scheme?.lowercased() == "https" {
            port = 443
        } else {
            port = 80
        }

        let path = url.path.isEmpty ? nil : url.path
        self.client = WebDAV(
            baseURL: url.absoluteString,
            port: port,
            username: username ?? url.user,
            password: password ?? url.password,
            path: path
        )
        self.filter = filter
        self.hostDisplay = url.host ?? "WebDAV"
        self.baseURL = url
        self.username = username ?? url.user
        self.password = password ?? url.password
    }

    func list(at path: String) async throws -> [RemoteItem] {
        let remotePath = normalizedRemotePath(path)
        let files = try await client.listFiles(atPath: remotePath, foldersFirst: true, includeSelf: false)
        return files.compactMap { file in
            guard filter.allows(name: file.fileName, isDirectory: file.isDirectory) else { return nil }
            let relativePath = file.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return RemoteItem(
                path: relativePath,
                name: file.fileName,
                isDirectory: file.isDirectory,
                size: Int(file.size),
                modifiedAt: file.lastModified
            )
        }
    }

    func openFile(at path: String) async throws -> String {
        let remotePath = normalizedRemotePath(path)

        if let urlWithCreds = credentialedURL(for: remotePath) {
            return urlWithCreds.absoluteString
        }

        // Fallback: download to a temporary file; WebDAVKit moves it if needed.
        let url = try await client.downloadFile(atPath: remotePath, useStream: false, destinationPath: nil)
        return url.absoluteString
    }

    private func normalizedRemotePath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "/" + trimmed
    }

    private func credentialedURL(for remotePath: String) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.user = username
        components.password = password

        let trimmed = remotePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let basePath = components.path
        let joined: String
        if trimmed.isEmpty {
            joined = basePath.isEmpty ? "/" : basePath
        } else if basePath.isEmpty || basePath == "/" {
            joined = "/" + trimmed
        } else if basePath.hasSuffix("/") {
            joined = basePath + trimmed
        } else {
            joined = basePath + "/" + trimmed
        }
        components.path = joined

        return components.url
    }
}
