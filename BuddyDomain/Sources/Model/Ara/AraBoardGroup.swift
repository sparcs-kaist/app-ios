//
//  AraBoardGroup.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

public struct AraBoardGroup: Identifiable, Hashable, Sendable {
  public let id: Int
  public let slug: String
  public let name: LocalizedString

  public init(id: Int, slug: String, name: LocalizedString) {
    self.id = id
    self.slug = slug
    self.name = name
  }
}

public extension AraBoardGroup {
  static let empty = Self(id: 999, slug: "extra", name: LocalizedString([
    "ko": "기타",
    "en": "Extra"
  ]))

  /// SF Symbol standing in for this group. Lives on the model because two screens
  /// need the same mapping now: the board list on iOS and the sidebar on macOS.
  var symbolName: String {
    switch slug {
    case "notice":
      "bell.badge.fill"
    case "talk":
      "text.bubble.fill"
    case "club":
      "person.2.fill"
    case "trade":
      "tag.fill"
    case "communication":
      "envelope.open.fill"
    default:
      "list.clipboard"
    }
  }
}
