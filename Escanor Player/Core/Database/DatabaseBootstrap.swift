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

        try migrator.migrate(database)
        defaultDatabase = database
        defaultSyncEngine = try SyncEngine(
            for: database,
            tables: SavedShareRecord.self
        )

        logger.debug("Database ready at \(database.path)")
    }
}

private let logger = Logger(subsystem: "EscanorPlayer", category: "Database")
