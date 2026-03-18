//
//  MapTab.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 18/03/2026.
//

import Foundation

public enum MapTab: String, CaseIterable {
  case nearby = "Nearby"
  case classrooms = "Classrooms"
  case olev = "OLEV"
  case search = "Search"

  public var symbol: String {
    switch self {
    case .nearby:
      "location.viewfinder"
    case .classrooms:
      "books.vertical.fill"
    case .olev:
      "bus.fill"
    case .search:
      "magnifyingglass"
    }
  }
}
