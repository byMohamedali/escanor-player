//
//  InteractionModels.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import SQLiteData
import GRDB

@Table
nonisolated struct PlaybackState: Identifiable {
    static let databaseTableName = "playbackStates"

    let id: UUID
    var mediaKey: String
    var userId: String
    var playhead: Double
    var duration: Double
    var completed: Bool
    var lastPlayedAt: Date?
    var lastDeviceId: String?
    var tmdbId: Int?
    var episodeTmdbId: Int?
    var updatedAt: Date
}

@Table
nonisolated struct MediaCollection: Identifiable {
    static let databaseTableName = "mediaCollections"

    let id: UUID
    var name: String
    var ownerId: String
    var isShared: Bool
    var createdAt: Date
    var updatedAt: Date
}

@Table
nonisolated struct MediaCollectionMembership: Identifiable {
    static let databaseTableName = "mediaCollectionMemberships"

    let id: UUID
    var collectionId: UUID
    var mediaKey: String
    var addedAt: Date
}

@Table
nonisolated struct UserFlags: Identifiable {
    // Aligning with SQLiteData's default pluralization to avoid trigger mismatches.
    static let databaseTableName = "userFlagses"

    let id: UUID
    var mediaKey: String
    var userId: String
    var hidden: Bool
    var pinned: Bool
    var updatedAt: Date
}

extension PlaybackState {
    static func migrate(db: Database) throws {
        try db.create(table: "playbackStates") { t in
            t.primaryKey("id", .text)
            t.column("mediaKey", .text).notNull()
            t.column("userId", .text).notNull()
            t.column("playhead", .double).notNull().defaults(to: 0)
            t.column("duration", .double).notNull().defaults(to: 0)
            t.column("completed", .boolean).notNull().defaults(to: false)
            t.column("lastPlayedAt", .datetime)
            t.column("lastDeviceId", .text)
            t.column("tmdbId", .integer)
            t.column("episodeTmdbId", .integer)
            t.column("updatedAt", .datetime).notNull()
        }
        try db.create(index: "idx_playback_media_user", on: "playbackStates", columns: ["mediaKey", "userId"])
    }
}

extension MediaCollection {
    static func migrate(db: Database) throws {
        try db.create(table: databaseTableName) { t in
            t.primaryKey("id", .text)
            t.column("name", .text).notNull()
            t.column("ownerId", .text).notNull()
            t.column("isShared", .boolean).notNull().defaults(to: false)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}

extension MediaCollectionMembership {
    static func migrate(db: Database) throws {
        try db.create(table: databaseTableName) { t in
            t.primaryKey("id", .text)
            t.column("collectionId", .text).notNull()
            t.column("mediaKey", .text).notNull()
            t.column("addedAt", .datetime).notNull()
        }
        try db.create(index: "idx_mediaCollectionMemberships", on: databaseTableName, columns: ["collectionId", "mediaKey"])
    }
}

extension UserFlags {
    static func migrate(db: Database) throws {
        try db.create(table: databaseTableName) { t in
            t.primaryKey("id", .text)
            t.column("mediaKey", .text).notNull()
            t.column("userId", .text).notNull()
            t.column("hidden", .boolean).notNull().defaults(to: false)
            t.column("pinned", .boolean).notNull().defaults(to: false)
            t.column("updatedAt", .datetime).notNull()
        }
        try db.create(index: "idx_userFlags_media_user", on: databaseTableName, columns: ["mediaKey", "userId"])
    }
}
