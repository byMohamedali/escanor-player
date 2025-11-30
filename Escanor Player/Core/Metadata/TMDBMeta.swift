//
//  TMDBMeta.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import SQLiteData
import GRDB

@Table
nonisolated struct TMDBMeta: Identifiable {
    static let databaseTableName = "tmdbMetas"

    let id: Int
    var type: String
    var backdropURL: String?
    var name: String?
    var overview: String?
    var posterURL: String?
    var releaseDate: Date?
    var rating: Double?
    var runTime: Int?
    var titleLogo: String?
    var titleLogoAspectRatio: Double?
    var ageRating: String?
    var lastFetchedAt: Date?
}

@Table
nonisolated struct EpisodeMeta: Identifiable {
    static let databaseTableName = "episodeMetas"

    let id: Int
    var seriesTmdbId: Int?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var mediaId: String?
    var title: String?
    var overview: String?
    var stillPath: String?
    var releasedDate: Date?
    var runtime: Int?
}

@Table
nonisolated struct TMDBGenre: Identifiable {
    static let databaseTableName = "tmdbGenres"

    let id: Int
    var type: String
    var name: String
}

@Table
nonisolated struct TMDBMediaGenre: Identifiable {
    static let databaseTableName = "tmdbMediaGenres"

    let id: UUID
    var tmdbId: Int
    var type: String
    var genreId: Int
}

extension TMDBMeta {
    static func migrate(db: Database) throws {
        try db.create(table: "tmdbMetas") { t in
            t.primaryKey("id", .integer)
            t.column("type", .text).notNull()
            t.column("backdropURL", .text)
            t.column("name", .text)
            t.column("overview", .text)
            t.column("posterURL", .text)
            t.column("releaseDate", .datetime)
            t.column("rating", .double)
            t.column("runTime", .integer)
            t.column("titleLogo", .text)
            t.column("titleLogoAspectRatio", .double)
            t.column("ageRating", .text)
            t.column("lastFetchedAt", .datetime)
        }
    }
}

extension EpisodeMeta {
    static func migrate(db: Database) throws {
        try db.create(table: "episodeMetas") { t in
            t.primaryKey("id", .integer)
            t.column("seriesTmdbId", .integer)
            t.column("seasonNumber", .integer)
            t.column("episodeNumber", .integer)
            t.column("mediaId", .text)
            t.column("title", .text)
            t.column("overview", .text)
            t.column("stillPath", .text)
            t.column("releasedDate", .datetime)
            t.column("runtime", .integer)
        }
    }
}

extension TMDBGenre {
    static func migrate(db: Database) throws {
        try db.create(table: "tmdbGenres") { t in
            t.primaryKey("id", .integer)
            t.column("type", .text).notNull()
            t.column("name", .text).notNull()
        }
    }
}

extension TMDBMediaGenre {
    static func migrate(db: Database) throws {
        try db.create(table: "tmdbMediaGenres") { t in
            t.primaryKey("id", .text)
            t.column("tmdbId", .integer).notNull()
            t.column("type", .text).notNull()
            t.column("genreId", .integer).notNull()
        }
        try db.create(index: "idx_tmdbMediaGenres_tmdb_type", on: "tmdbMediaGenres", columns: ["tmdbId", "type"])
    }
}
