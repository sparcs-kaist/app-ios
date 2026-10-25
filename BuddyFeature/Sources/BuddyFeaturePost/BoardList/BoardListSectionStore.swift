//
//  BoardListSectionStore.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/10/2026.
//

import Foundation
import BuddyDomain

/// The sections the reader chose for the Boards list, kept on this device.
struct BoardListSectionStore {
  /// Also read by the Boards list's `@AppStorage`, to follow changes made in Settings.
  static let key = "BoardListSections"

  var defaults: UserDefaults = .standard

  /// The saved sections, or the default ones if none were saved or they can't be read.
  func load() -> [BoardListSection] {
    guard let data = defaults.data(forKey: Self.key),
          let sections = try? JSONDecoder().decode([BoardListSection].self, from: data) else {
      return BoardListSection.defaults
    }
    return sections
  }

  func save(_ sections: [BoardListSection]) {
    if let data = try? JSONEncoder().encode(sections) {
      defaults.set(data, forKey: Self.key)
    }
  }
}
