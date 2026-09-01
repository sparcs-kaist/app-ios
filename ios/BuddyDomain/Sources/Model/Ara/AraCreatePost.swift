//
//  AraCreatePost.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

public struct AraCreatePost: Sendable {
  public let title: String
  public let content: String
  public let attachments: [AraAttachment]
  public let topic: AraBoardTopic?
  public let isNSFW: Bool
  public let isPolitical: Bool
  public let nicknameType: AraPostNicknameType
  public let board: AraBoard

  public init(
    title: String,
    content: String,
    attachments: [AraAttachment],
    topic: AraBoardTopic?,
    isNSFW: Bool,
    isPolitical: Bool,
    nicknameType: AraPostNicknameType,
    board: AraBoard
  ) {
    self.title = title
    self.content = content
    self.attachments = attachments
    self.topic = topic
    self.isNSFW = isNSFW
    self.isPolitical = isPolitical
    self.nicknameType = nicknameType
    self.board = board
  }
}
