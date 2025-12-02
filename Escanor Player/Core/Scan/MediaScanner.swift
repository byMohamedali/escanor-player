//
//  MediaScanner.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import Dependencies
import CryptoKit
import GRDB
import Combine
internal import StructuredQueriesCore
import SQLiteData

/// Lightweight scanner for local shares. SMB and other protocols can be wired later.
@MainActor
final class MediaScanner: ObservableObject {
    @Dependency(\.defaultDatabase) private var database
    @Published private(set) var isScanning = false

    private let videoExtensions: Set<String> = [
        "mp4", "m4v", "mkv", "mov", "avi", "wmv", "flv", "mpg", "mpeg", "ts", "m2ts"
    ]

    func scanAllShares() async {
        guard !isScanning else { return }
        isScanning = true
        do {
            let shares: [SavedShareRecord] = try await database.read { db in
                try SavedShareRecord.all.fetchAll(db)
            }

            for share in shares {
                guard let kind = share.kind else { continue }
                switch kind {
                case .localFolder:
                    if let resolved = resolvedURL(for: kind) {
                        await scanLocalFolder(url: resolved, share: share)
                    }
                case .smb(let host, let username, let password):
//                    await scanSMBShare(share: share, host: host, username: username, password: password)
                    continue
                default:
                    continue
                }
            }
        } catch {
#if DEBUG
            print("Scan failed: \(error)")
#endif
        }
        isScanning = false
    }

    // MARK: - Private

    private func resolvedURL(for kind: SavedShareKind) -> URL? {
        switch kind {
        case .localFolder(let url, let bookmark):
            if let bookmark {
                var stale = false
                if let resolved = try? URL(
                    resolvingBookmarkData: bookmark,
                    options: [.withoutUI],
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                ) {
                    return resolved
                }
            }
            return url
        default:
            return nil
        }
    }

    private func scanSMBShare(share: SavedShareRecord, host: String, username: String?, password: String?) async {
        let smb = SMBSource(host: host, username: username, password: password)
        do {
            let roots = share.toDomain()?.includePaths ?? []
            let targets = roots.isEmpty ? ["/"] : roots
            for root in targets {
                try await scanSMBPath(smb: smb, share: share, path: root, depth: 0)
            }
        } catch {
#if DEBUG
            print("SMB scan failed: \(error)")
#endif
        }
    }

    private func scanSMBPath(smb: SMBSource, share: SavedShareRecord, path: String, depth: Int) async throws {
        if depth > 4 { return }
        let items = try await smb.list(at: path)
        let now = Date()
        for item in items {
            if item.isDirectory {
                try await scanSMBPath(smb: smb, share: share, path: item.path, depth: depth + 1)
                continue
            }

            let key = mediaKey(for: share.id, smbPath: item.path, size: item.size ?? 0, mtime: item.modifiedAt?.timeIntervalSince1970 ?? 0)
            let guessed = guess(from: URL(fileURLWithPath: item.name))
            try await insertOrUpdateMedia(
                MediaItem(
                    id: key,
                    shareId: share.id,
                    path: item.path,
                    size: item.size,
                    mtime: item.modifiedAt?.timeIntervalSince1970,
                    kind: guessed.kind,
                    tmdbId: nil,
                    seriesTmdbId: nil,
                    episodeTmdbId: nil,
                    seasonNumber: guessed.season,
                    episodeNumber: guessed.episode,
                    titleGuess: guessed.title,
                    yearGuess: guessed.year,
                    discoveredAt: now,
                    lastSeenAt: now
                )
            )
        }
    }

    private func scanLocalFolder(url: URL, share: SavedShareRecord) async {
        guard url.isFileURL else { return }
        let fm = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .fileResourceIdentifierKey
        ]

        var stopAccess = false
        let granted = url.startAccessingSecurityScopedResource()
        if granted { stopAccess = true }
        if !granted, !fm.isReadableFile(atPath: url.path) {
            return
        }
        defer {
            if stopAccess { url.stopAccessingSecurityScopedResource() }
        }

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else { return }

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { url, error in
#if DEBUG
                print("Enumerator error at \(url): \(error)")
#endif
                return true
            }
        ) else { return }

        while let next = enumerator.nextObject() as? URL {
            do {
                let values = try next.resourceValues(forKeys: resourceKeys)
                guard values.isRegularFile == true else { continue }
                let ext = next.pathExtension.lowercased()
                guard videoExtensions.contains(ext) else { continue }

                let size = values.fileSize
                let mtime = values.contentModificationDate?.timeIntervalSince1970
                let identifier = values.fileResourceIdentifier as? Data
                let key = mediaKey(
                    for: share.id,
                    root: url,
                    fileURL: next,
                    size: size ?? 0,
                    mtime: mtime ?? 0,
                    resourceIdentifier: identifier
                )

                let guessed = guess(from: next)
                let now = Date()

                try await insertOrUpdateMediaUsingDraft(
                    MediaItem(
                        id: key,
                        shareId: share.id,
                        path: next.path,
                        size: size,
                        mtime: mtime,
                        kind: guessed.kind,
                        tmdbId: nil,
                        seriesTmdbId: nil,
                        episodeTmdbId: nil,
                        seasonNumber: guessed.season,
                        episodeNumber: guessed.episode,
                        titleGuess: guessed.title,
                        yearGuess: guessed.year,
                        discoveredAt: now,
                        lastSeenAt: now
                    )
                )
            } catch {
#if DEBUG
                print("Failed to index \(next): \(error)")
#endif
            }
        }
    }

    private func insertOrUpdateMedia(_ item: MediaItem) async throws {
        try await database.write { db in
            try db.execute(
                sql: """
                INSERT INTO mediaItems
                (id, shareId, path, size, mtime, kind, tmdbId, seriesTmdbId, episodeTmdbId, seasonNumber, episodeNumber, titleGuess, yearGuess, discoveredAt, lastSeenAt)
                VALUES (:id, :shareId, :path, :size, :mtime, :kind, :tmdbId, :seriesTmdbId, :episodeTmdbId, :seasonNumber, :episodeNumber, :titleGuess, :yearGuess, :discoveredAt, :lastSeenAt)
                ON CONFLICT(id) DO UPDATE SET
                    path = excluded.path,
                    size = excluded.size,
                    mtime = excluded.mtime,
                    kind = excluded.kind,
                    tmdbId = COALESCE(mediaItems.tmdbId, excluded.tmdbId),
                    seriesTmdbId = COALESCE(mediaItems.seriesTmdbId, excluded.seriesTmdbId),
                    episodeTmdbId = COALESCE(mediaItems.episodeTmdbId, excluded.episodeTmdbId),
                    seasonNumber = COALESCE(mediaItems.seasonNumber, excluded.seasonNumber),
                    episodeNumber = COALESCE(mediaItems.episodeNumber, excluded.episodeNumber),
                    titleGuess = COALESCE(mediaItems.titleGuess, excluded.titleGuess),
                    yearGuess = COALESCE(mediaItems.yearGuess, excluded.yearGuess),
                    lastSeenAt = excluded.lastSeenAt,
                    discoveredAt = COALESCE(mediaItems.discoveredAt, excluded.discoveredAt)
                """,
                arguments: [
                    "id": item.id,
                    "shareId": item.shareId.uuidString,
                    "path": item.path,
                    "size": item.size,
                    "mtime": item.mtime,
                    "kind": item.kind.rawValue,
                    "tmdbId": item.tmdbId,
                    "seriesTmdbId": item.seriesTmdbId,
                    "episodeTmdbId": item.episodeTmdbId,
                    "seasonNumber": item.seasonNumber,
                    "episodeNumber": item.episodeNumber,
                    "titleGuess": item.titleGuess,
                    "yearGuess": item.yearGuess,
                    "discoveredAt": item.discoveredAt?.timeIntervalSince1970,
                    "lastSeenAt": item.lastSeenAt?.timeIntervalSince1970
                ]
            )
        }
    }

    // Alternate path using StructuredQueries with Draft for comparison/debugging.
    // Note: This attempts a simple insert and ignores conflicts.
    private func insertOrUpdateMediaUsingDraft(_ item: MediaItem) async throws {
        try await database.write { db in
            do {
                try MediaItem.upsert { MediaItem.Draft(item) }
                .execute(db)
            } catch {
#if DEBUG
                print("Structured insert failed (will rely on SQL upsert): \(error)")
#endif
            }
        }
    }

    private func mediaKey(for shareId: UUID, root: URL, fileURL: URL, size: Int, mtime: TimeInterval, resourceIdentifier: Data?) -> String {
        if let resourceIdentifier {
            let input = "\(shareId.uuidString.lowercased())|\(resourceIdentifier.base64EncodedString())|\(size)"
            let hash = SHA256.hash(data: Data(input.utf8))
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }

        let relativePath = fileURL.path.replacingOccurrences(of: root.path, with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let input = "\(shareId.uuidString.lowercased())|\(relativePath.lowercased())|\(size)|\(mtime)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func mediaKey(for shareId: UUID, smbPath: String, size: Int, mtime: TimeInterval) -> String {
        let normalized = smbPath.lowercased()
        let input = "\(shareId.uuidString.lowercased())|\(normalized)|\(size)|\(mtime)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func guess(from url: URL) -> (title: String?, year: Int?, season: Int?, episode: Int?, kind: MediaItem.Kind) {
        let filename = url.deletingPathExtension().lastPathComponent
        // Minimal guess: if it has SxxExx pattern, mark as episode.
        let pattern = #"s(\d{1,2})e(\d{1,3})"#
        if let range = filename.range(of: pattern, options: .regularExpression) {
            let match = String(filename[range]).lowercased()
            let parts = match.dropFirst().split(separator: "e")
            let season = Int(parts.first ?? "")
            let episode = Int(parts.last ?? "")
            return (title: cleanTitle(filename), year: nil, season: season, episode: episode, kind: .tvEpisode)
        }
        return (title: cleanTitle(filename), year: nil, season: nil, episode: nil, kind: .movie)
    }

    private func cleanTitle(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
