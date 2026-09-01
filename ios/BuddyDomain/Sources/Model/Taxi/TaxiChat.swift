//
//  TaxiChat.swift
//  soap
//
//  Created by Soongyu Kwon on 16/07/2025.
//

import Foundation

public struct TaxiChat: Identifiable, Equatable, Hashable, Sendable {
  public enum ChatType: String, Sendable {
    // User sent type
    case text               // normal message
    case s3img              // S3 uploaded image
    case settlement         // settlement message
    case payment            // payment message
    case account            // account message

    // General type
    case entrance = "in"   // enterance message
    case exit = "out"       // exit message

    // Bot sent type
    case share
    case departure
    case arrival
    
    case unknown
  }

  public let id = UUID()
  public let roomID: String
  public let type: ChatType
  public let authorID: String?
  public let authorName: String?
  public let authorProfileURL: URL?
  public let authorIsWithdrew: Bool?
  public let content: String
  public let time: Date
  public let isValid: Bool
  public let inOutNames: [String]?

  public init(
    roomID: String,
    type: ChatType,
    authorID: String?,
    authorName: String?,
    authorProfileURL: URL?,
    authorIsWithdrew: Bool?,
    content: String,
    time: Date,
    isValid: Bool,
    inOutNames: [String]?
  ) {
    self.roomID = roomID
    self.type = type
    self.authorID = authorID
    self.authorName = authorName
    self.authorProfileURL = authorProfileURL
    self.authorIsWithdrew = authorIsWithdrew
    self.content = content
    self.time = time
    self.isValid = isValid
    self.inOutNames = inOutNames
  }
}
