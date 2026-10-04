//
//  BeaconSighting.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// One Bluetooth advertisement heard from another phone on Add Friends.
public struct BeaconSighting: Sendable, Equatable {
  /// The 12-byte session token carried in the beacon's service UUID.
  public let token: Data
  public let rssi: Int
  public let seenAt: Date

  public init(token: Data, rssi: Int, seenAt: Date) {
    self.token = token
    self.rssi = rssi
    self.seenAt = seenAt
  }
}
