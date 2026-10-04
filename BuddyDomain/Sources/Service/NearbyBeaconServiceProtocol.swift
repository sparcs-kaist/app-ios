//
//  NearbyBeaconServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// Advertises this phone's nearby token over Bluetooth Low Energy and reports
/// tokens heard from other phones.
public protocol NearbyBeaconServiceProtocol: Sendable {
  var authorization: NearbyBluetoothAuthorization { get }

  /// Emits whenever the authorization or Bluetooth power state changes,
  /// starting with the current value. Asking for it may show the system
  /// Bluetooth prompt.
  func authorizationUpdates() -> AsyncStream<NearbyBluetoothAuthorization>

  /// Starts advertising `token` and scanning. The stream finishes on `stop()`
  /// or when Bluetooth becomes unavailable.
  func start(advertising token: Data) -> AsyncThrowingStream<BeaconSighting, Error>
  func stop()
}
