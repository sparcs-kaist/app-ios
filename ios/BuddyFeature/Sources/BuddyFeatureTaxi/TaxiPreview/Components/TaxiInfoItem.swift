//
//  TaxiInfoItem.swift
//  soap
//
//  Created by Minjae Kim on 5/4/25.
//

import SwiftUI

enum TaxiInfoItem: Identifiable {
    var id: String {
        switch self {
        case .plain(let label, _): return label
        case .withIcon(let label, _, _): return label
        }
    }
    
    case plain(label: String, value: String)
    case withIcon(label: String, value: String, systemImage: String)
}
