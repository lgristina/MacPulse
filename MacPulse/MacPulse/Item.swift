//
//  Item.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/10/25.
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
