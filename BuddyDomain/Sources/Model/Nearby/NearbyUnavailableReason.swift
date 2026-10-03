//
//  NearbyUnavailableReason.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

/// Why nearby discovery can't run.
public enum NearbyUnavailableReason: Sendable, Equatable, Hashable {
  /// Bluetooth permission hasn't been asked for yet.
  case permissionRequired
  /// The person declined Bluetooth access; only Settings can change it.
  case permissionDenied
  case bluetoothOff
  /// The device can't advertise or scan over Bluetooth Low Energy.
  case unsupported
}
