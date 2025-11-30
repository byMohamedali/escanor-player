//
//  DatabaseBootstrap.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import Dependencies
import SQLiteData
import GRDB
import OSLog

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase()

        var migrator = DatabaseMigrator()
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        migrator.registerMigration("createSavedShares") { db in
            try SavedShareRecord.migrate(db: db)
        }
        migrator.registerMigration("createMediaItems") { db in
            try MediaItem.migrate(db: db)
        }
        migrator.registerMigration("createTMDBMetas") { db in
            try TMDBMeta.migrate(db: db)
            try EpisodeMeta.migrate(db: db)
            try TMDBGenre.migrate(db: db)
            try TMDBMediaGenre.migrate(db: db)
        }
        migrator.registerMigration("createInteractions") { db in
            try PlaybackState.migrate(db: db)
            try MediaCollection.migrate(db: db)
            try MediaCollectionMembership.migrate(db: db)
            try UserFlags.migrate(db: db)
        }

        try migrator.migrate(database)
        defaultDatabase = database
        defaultSyncEngine = try SyncEngine(
            for: database,
            tables: SavedShareRecord.self,
            PlaybackState.self,
            MediaCollection.self,
            MediaCollectionMembership.self,
            UserFlags.self
        )

        logger.debug("Database ready at \(database.path)")
    }
}

private let logger = Logger(subsystem: "EscanorPlayer", category: "Database")
