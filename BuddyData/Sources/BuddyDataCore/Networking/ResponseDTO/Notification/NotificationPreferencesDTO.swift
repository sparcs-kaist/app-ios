//
//  NotificationPreferencesDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 29/10/2026.
//

import Foundation
import BuddyDomain

struct NotificationPreferencesDTO: Decodable {
  let preferences: [NotificationPreferenceDTO]

  /// Whether each kind of notification is on. Kinds this version of the app doesn't know are left
  /// out, so the server can add new ones.
  func toModel() -> [NotificationCategory: Bool] {
    preferences.reduce(into: [:]) { result, preference in
      guard let category = NotificationCategory(rawValue: preference.category) else { return }
      result[category] = preference.isEnabled
    }
  }
}

struct NotificationPreferenceDTO: Decodable {
  let category: String
  let isEnabled: Bool

  enum CodingKeys: String, CodingKey {
    case category
    case isEnabled = "is_enabled"
  }
}
