//
//  NearbySession.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import CryptoKit

/// The keys and identifiers for one visit to Add Friends. Nothing is kept once
/// the screen closes; the next visit gets a new key and so a new token.
public struct NearbySession: Sendable {
  public let privateKey: P256.KeyAgreement.PrivateKey
  public let publicKeyX963: Data
  /// Broadcast over BLE.
  public let token: Data
  public let lookupId: Data
  public let presenceKey: SymmetricKey
  /// Proves to the relay that we own this presence and its mailbox.
  public let ownerSecret: Data

  public init(
    privateKey: P256.KeyAgreement.PrivateKey = P256.KeyAgreement.PrivateKey(),
    ownerSecret: Data? = nil
  ) {
    self.privateKey = privateKey
    self.publicKeyX963 = privateKey.publicKey.x963Representation
    self.token = NearbyCrypto.token(forPublicKey: publicKeyX963)
    self.lookupId = NearbyCrypto.lookupId(for: token)
    self.presenceKey = NearbyCrypto.presenceKey(for: token)
    self.ownerSecret = ownerSecret ?? SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
  }
}
