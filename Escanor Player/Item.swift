//
//  Item.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
