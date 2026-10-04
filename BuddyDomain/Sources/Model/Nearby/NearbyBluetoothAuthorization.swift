//
//  NearbyBluetoothAuthorization.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// Whether the beacon can run right now.
public enum NearbyBluetoothAuthorization: Sendable, Equatable {
  case notDetermined
  case denied
  case allowed
  case poweredOff
  case unsupported

  /// What the Add Friends screen should show instead of discovery, or `nil`
  /// when discovery can run.
  public var unavailableReason: NearbyUnavailableReason? {
    switch self {
    case .notDetermined: .permissionRequired
    case .denied: .permissionDenied
    case .poweredOff: .bluetoothOff
    case .unsupported: .unsupported
    case .allowed: nil
    }
  }
}
