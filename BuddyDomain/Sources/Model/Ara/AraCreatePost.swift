//
//  AraCreatePost.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

public struct AraCreatePost: Sendable {
  public let title: String
  /// The body as Ara stores it: a Tiptap document serialised as JSON.
  public let content: String
  /// Uploaded photos and files, by id.
  public let attachmentIDs: [Int]
  public let topic: AraBoardTopic?
  public let isNSFW: Bool
  public let isPolitical: Bool
  public let nicknameType: AraPostNicknameType
  public let board: AraBoard
  /// The price of a Market post.
  public let marketListing: AraMarketListing?

  public init(
    title: String,
    content: String,
    attachmentIDs: [Int],
    topic: AraBoardTopic?,
    isNSFW: Bool,
    isPolitical: Bool,
    nicknameType: AraPostNicknameType,
    board: AraBoard,
    marketListing: AraMarketListing? = nil
  ) {
    self.title = title
    self.content = content
    self.attachmentIDs = attachmentIDs
    self.topic = topic
    self.isNSFW = isNSFW
    self.isPolitical = isPolitical
    self.nicknameType = nicknameType
    self.board = board
    self.marketListing = marketListing
  }
}
