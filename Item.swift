//
//  Item.swift
//  MySNS
//
//  Created by 日下拓海 on 2024/09/05.
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
