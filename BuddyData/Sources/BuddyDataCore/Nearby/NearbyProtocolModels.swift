//
//  NearbyProtocolModels.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// What a nearby phone publishes about itself, encrypted under its presence key.
public struct NearbyPresenceCard: Codable, Sendable, Equatable {
  public let v: Int
  /// Base64url of the 65-byte X9.63 public key.
  public let pub: String
  public let name: String
  public let platform: String
  /// Random per app launch (never stored), so a phone that leaves Add Friends
  /// and comes back with a new session replaces its old bubble instead of
  /// showing twice. Optional: older cards don't carry it.
  public let device: String?

  public init(v: Int = 1, pub: String, name: String, platform: String = "ios", device: String? = nil) {
    self.v = v
    self.pub = pub
    self.name = name
    self.platform = platform
    self.device = device
  }

  /// Names are capped at 64 UTF-8 bytes, cut on a character boundary.
  static func truncatedName(_ name: String) -> String {
    var result = ""
    for character in name.trimmingCharacters(in: .whitespacesAndNewlines) {
      guard result.utf8.count + String(character).utf8.count <= 64 else { break }
      result.append(character)
    }
    return result
  }
}

public enum NearbyMessageType: String, Sendable {
  case request
  case accept
  case confirm
  case decline
  case cancel
}

/// The decrypted body of a mailbox message.
public struct NearbyMessageBody: Codable, Sendable, Equatable {
  public let v: Int
  /// Kept as a string so unknown future types decode and are then ignored.
  public let type: String
  public let msgId: String
  /// Milliseconds since 1970.
  public let sentAt: Int64
  public let inReplyTo: String?
  public let friendCode: String?

  public init(
    type: NearbyMessageType,
    msgId: String = UUID().uuidString.lowercased(),
    sentAt: Int64,
    inReplyTo: String? = nil,
    friendCode: String? = nil
  ) {
    self.v = 1
    self.type = type.rawValue
    self.msgId = msgId
    self.sentAt = sentAt
    self.inReplyTo = inReplyTo
    self.friendCode = friendCode
  }

  public var messageType: NearbyMessageType? {
    NearbyMessageType(rawValue: type)
  }
}
