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
}
