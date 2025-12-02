//
//  RemoteSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation

struct RemoteItem: Identifiable {
    let id: UUID = UUID()
    let path: String
    let name: String
    let isDirectory: Bool
    let size: Int?
    let modifiedAt: Date?
}

protocol RemoteSource {
    var displayName: String { get }
    func list(at path: String) async throws -> [RemoteItem]
    func openFile(at path: String) async throws -> String
}

