//
//  MediaItem.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import SQLiteData
import GRDB

@Table
nonisolated struct MediaItem: Identifiable {
    static let databaseTableName = "mediaItems"

    enum Kind: String, Codable, QueryRepresentable, QueryBindable {
        case movie
        case tvEpisode
        case other
    }

    let id: UUID
    var shareId: UUID
    var path: String
    var mediaKey: String
    var size: Int?
    var mtime: TimeInterval?
    var kind: Kind
    var tmdbId: Int?
    var seriesTmdbId: Int?
    var episodeTmdbId: Int?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var titleGuess: String?
    var yearGuess: Int?
    var discoveredAt: Date?
    var lastSeenAt: Date?

    init(
        id: UUID = UUID(),
        shareId: UUID,
        path: String,
        mediaKey: String,
        size: Int? = nil,
        mtime: TimeInterval? = nil,
        kind: Kind = .other,
        tmdbId: Int? = nil,
        seriesTmdbId: Int? = nil,
        episodeTmdbId: Int? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        titleGuess: String? = nil,
        yearGuess: Int? = nil,
        discoveredAt: Date? = nil,
        lastSeenAt: Date? = nil
    ) {
        self.id = id
        self.shareId = shareId
        self.path = path
        self.mediaKey = mediaKey
        self.size = size
        self.mtime = mtime
        self.kind = kind
        self.tmdbId = tmdbId
        self.seriesTmdbId = seriesTmdbId
        self.episodeTmdbId = episodeTmdbId
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.titleGuess = titleGuess
        self.yearGuess = yearGuess
        self.discoveredAt = discoveredAt
        self.lastSeenAt = lastSeenAt
    }
}

extension MediaItem {
    static func migrate(db: Database) throws {
        try db.create(table: "mediaItems") { t in
            t.primaryKey("id", .text).unique()
            t.column("shareId", .text).notNull()
            t.column("path", .text).notNull()
            t.column("mediaKey", .text).notNull().unique()
            t.column("size", .integer)
            t.column("mtime", .double)
            t.column("kind", .text).notNull()
            t.column("tmdbId", .integer)
            t.column("seriesTmdbId", .integer)
            t.column("episodeTmdbId", .integer)
            t.column("seasonNumber", .integer)
            t.column("episodeNumber", .integer)
            t.column("titleGuess", .text)
            t.column("yearGuess", .integer)
            t.column("discoveredAt", .datetime)
            t.column("lastSeenAt", .datetime)
        }
        try db.create(index: "idx_mediaItems_share", on: "mediaItems", columns: ["shareId"])
    }
}
