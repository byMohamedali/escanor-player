//
//  ItemFilter.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation

struct ItemFilter {
    let allowedExtensions: Set<String>
    let includeDirectories: Bool
    let includeHidden: Bool

    init(
        allowedExtensions: Set<String> = ItemFilter.videoExtensions,
        includeDirectories: Bool = true,
        includeHidden: Bool = false
    ) {
        self.allowedExtensions = allowedExtensions
        self.includeDirectories = includeDirectories
        self.includeHidden = includeHidden
    }

    func allows(url: URL, isDirectory: Bool) -> Bool {
        let name = url.lastPathComponent
        return allows(name: name, isDirectory: isDirectory)
    }

    func allows(item: RemoteItem) -> Bool {
        allows(name: item.name, isDirectory: item.isDirectory)
    }

    func allows(name: String, isDirectory: Bool) -> Bool {
        if !includeHidden && name.hasPrefix(".") {
            return false
        }
        if isDirectory {
            return includeDirectories
        }
        let ext = (name as NSString).pathExtension.lowercased()
        return allowedExtensions.isEmpty || allowedExtensions.contains(ext)
    }
}

extension ItemFilter {
    static let videoExtensions: Set<String> = [
        "mp4", "m4v", "mkv", "mov", "avi", "wmv", "flv", "mpg", "mpeg", "ts", "m2ts"
    ]

    static let videoAndDirectories = ItemFilter()
}
