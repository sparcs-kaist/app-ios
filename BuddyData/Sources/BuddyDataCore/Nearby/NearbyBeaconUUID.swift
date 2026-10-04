//
//  NearbyBeaconUUID.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// The BLE service UUID that carries a nearby token: the magic prefix
/// `b0dd1e01` followed by the 12-byte token. Always built from and parsed as
/// the string form so byte order on the air never matters.
public enum NearbyBeaconUUID {
  public static let prefix = "b0dd1e01"
  private static let prefixBytes: [UInt8] = [0xB0, 0xDD, 0x1E, 0x01]

  public static func string(for token: Data) -> String? {
    guard token.count == NearbyCrypto.tokenLength else { return nil }
    let hex = token.hexString
    let parts = [
      prefix,
      String(hex.prefix(4)),
      String(hex.dropFirst(4).prefix(4)),
      String(hex.dropFirst(8).prefix(4)),
      String(hex.dropFirst(12))
    ]
    return parts.joined(separator: "-")
  }

  /// The token in a Buddy beacon UUID, or `nil` for any other UUID.
  public static func token(from uuidString: String) -> Data? {
    guard let uuid = UUID(uuidString: uuidString) else { return nil }
    let bytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
    guard Array(bytes.prefix(4)) == prefixBytes else { return nil }
    return Data(bytes.dropFirst(4))
  }
}
