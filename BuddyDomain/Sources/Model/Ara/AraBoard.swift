//
//  AraBoard.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

public struct AraBoard: Identifiable, Hashable, Sendable {
  public let id: Int
  public let slug: String
  public let name: LocalizedString
  public let group: AraBoardGroup
  public let topics: [AraBoardTopic]?
  public let isReadOnly: Bool
  public let userReadable: Bool?
  public let userWritable: Bool?
  /// The names a post may be written under on this board; empty when unknown.
  public let nicknameTypes: [AraPostNicknameType]

  public init(
    id: Int,
    slug: String,
    name: LocalizedString,
    group: AraBoardGroup,
    topics: [AraBoardTopic]?,
    isReadOnly: Bool,
    userReadable: Bool?,
    userWritable: Bool?,
    nicknameTypes: [AraPostNicknameType] = []
  ) {
    self.id = id
    self.slug = slug
    self.name = name
    self.group = group
    self.topics = topics
    self.isReadOnly = isReadOnly
    self.userReadable = userReadable
    self.userWritable = userWritable
    self.nicknameTypes = nicknameTypes
  }

  /// Whether a post here can be written under `type`. Unknown boards allow a nickname or anonymity.
  public func allows(_ type: AraPostNicknameType) -> Bool {
    nicknameTypes.isEmpty ? type != .realName : nicknameTypes.contains(type)
  }
}
