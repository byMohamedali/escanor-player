//
//  LocalSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation

struct LocalSource: RemoteSource {
    let root: URL
    let bookmarkData: Data?
    let filter: ItemFilter

    init(root: URL, bookmarkData: Data?, filter: ItemFilter = .videoAndDirectories) {
        self.root = root
        self.bookmarkData = bookmarkData
        self.filter = filter
    }

    var displayName: String { root.lastPathComponent }

    func list(at path: String) async throws -> [RemoteItem] {
        try withAccess(path: path) { base in
            let fm = FileManager.default
            let contents = try fm.contentsOfDirectory(
                at: base,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: filter.includeHidden ? [] : [.skipsHiddenFiles]
            )
            let filtered = try contents.compactMap { url -> RemoteItem? in
                let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let isDir = values.isDirectory ?? false
                guard filter.allows(url: url, isDirectory: isDir) else { return nil }

                // Preserve paths relative to the saved root so we don't duplicate the root when reopening.
                let rootPath = (resolveRoot() ?? base).standardizedFileURL.path
                let fullPath = url.standardizedFileURL.path
                let relative: String = {
                    if fullPath.hasPrefix(rootPath) {
                        let suffix = fullPath.dropFirst(rootPath.count)
                        return suffix.hasPrefix("/") ? String(suffix.dropFirst()) : String(suffix)
                    } else {
                        return url.lastPathComponent
                    }
                }()

                return RemoteItem(
                    path: relative,
                    name: url.lastPathComponent,
                    isDirectory: isDir,
                    size: values.fileSize,
                    modifiedAt: values.contentModificationDate
                )
            }
            return filtered
        }
    }

    func openFile(at path: String) async throws -> String {
        try withAccess(path: path) { url in
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                throw NSError(domain: "LocalSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not readable"])
            }
            return url.absoluteString
        }
    }

    // MARK: - Access Helpers

    private func resolveRoot() -> URL? {
        var resolved = root
        var stale = false
        if let bookmarkData,
           let bookmarkURL = try? URL(
               resolvingBookmarkData: bookmarkData,
               options: [.withoutUI],
               relativeTo: nil,
               bookmarkDataIsStale: &stale
           ) {
            resolved = bookmarkURL
        }
        return resolved
    }

    private func withAccess<T>(path: String, _ work: (URL) throws -> T) throws -> T {
        guard let base = resolveRoot() else {
            throw NSError(domain: "LocalSource", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid bookmark or URL"])
        }

        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let target = trimmed.isEmpty ? base : base.appendingPathComponent(trimmed)

        let granted = target.startAccessingSecurityScopedResource()
        defer {
            if granted { target.stopAccessingSecurityScopedResource() }
        }

        guard granted || FileManager.default.isReadableFile(atPath: target.path) else {
            throw NSError(domain: "LocalSource", code: -3, userInfo: [NSLocalizedDescriptionKey: "Access denied for \(target.path)"])
        }

        return try work(target)
    }
}
