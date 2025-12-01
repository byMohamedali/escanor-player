//
//  LocalSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation

struct LocalSource: RemoteSource {
    let root: URL

    var displayName: String { root.lastPathComponent }

    func list(at path: String) async throws -> [RemoteItem] {
        let fm = FileManager.default
        let base = root.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        let contents = try fm.contentsOfDirectory(at: base, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles])
        return try contents.map { url in
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            return RemoteItem(
                path: url.path,
                name: url.lastPathComponent,
                isDirectory: values.isDirectory ?? false,
                size: values.fileSize,
                modifiedAt: values.contentModificationDate
            )
        }
    }

    func openFile(at path: String) async throws -> URL {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw NSError(domain: "LocalSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not readable"])
        }
        return url
    }
}

