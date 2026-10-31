//
//  AraUpdatePost.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation

/// The parts of a post its author can change. Ara keeps the board, topic and name type fixed.
public struct AraUpdatePost: Sendable {
  public let title: String
  /// The body as Ara stores it: a Tiptap document serialised as JSON.
  public let content: String
  /// Every attachment the post keeps, including ones it already had.
  public let attachmentIDs: [Int]
  public let isNSFW: Bool
  public let isPolitical: Bool
  /// The price of a Market post; `nil` leaves it as it was.
  public let marketListing: AraMarketListing?

  public init(
    title: String,
    content: String,
    attachmentIDs: [Int],
    isNSFW: Bool,
    isPolitical: Bool,
    marketListing: AraMarketListing? = nil
  ) {
    self.title = title
    self.content = content
    self.attachmentIDs = attachmentIDs
    self.isNSFW = isNSFW
    self.isPolitical = isPolitical
    self.marketListing = marketListing
  }
}
