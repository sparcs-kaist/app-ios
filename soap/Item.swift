//
//  Item.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
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
