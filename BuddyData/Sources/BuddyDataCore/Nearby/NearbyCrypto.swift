//
//  NearbyCrypto.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import CryptoKit

public enum NearbyCryptoError: Error, Equatable {
  case malformedToken
  case malformedPresence
  /// The presence's public key doesn't hash to the token we heard, so the
  /// relay (or someone else) substituted it.
  case commitmentMismatch
}

/// The nearby protocol (v1) primitives. Every value here must match the
/// Android implementation byte for byte; `nearby-test-vectors.json` pins them.
public enum NearbyCrypto {
  public static let tokenLength = 12

  static let lookupDomain = Data("buddy-nearby-v1/lookup".utf8)
  static let presenceDomain = Data("buddy-nearby-v1/presence".utf8)
  static let headerDomain = Data("buddy-nearby-v1/header".utf8)
  static let pairDomain = Data("buddy-nearby-v1/pair".utf8)
  static let bodyDomain = Data("buddy-nearby-v1/body".utf8)

  // MARK: - Identifiers

  /// The first 12 bytes of SHA-256 of the X9.63 public key: broadcast over
  /// BLE and a commitment to that key.
  public static func token(forPublicKey x963: Data) -> Data {
    Data(SHA256.hash(data: x963).prefix(tokenLength))
  }

  /// The relay's key for a presence and its mailbox.
  public static func lookupId(for token: Data) -> Data {
    Data(SHA256.hash(data: lookupDomain + token))
  }

  /// Anyone who heard the token can derive this, which is the point: it opens
  /// the presence card and lets them write to the mailbox.
  public static func presenceKey(for token: Data) -> SymmetricKey {
    // An empty salt is RFC 5869's default of 32 zero bytes, as on Android.
    HKDF<SHA256>.deriveKey(
      inputKeyMaterial: SymmetricKey(data: token),
      salt: Data(),
      info: presenceDomain,
      outputByteCount: 32
    )
  }

  public static func pairKey(
    privateKey: P256.KeyAgreement.PrivateKey,
    peerPublicKey: P256.KeyAgreement.PublicKey,
    myToken: Data,
    peerToken: Data
  ) throws -> SymmetricKey {
    let shared = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
    let (low, high) = myToken.lexicographicallyPrecedes(peerToken)
      ? (myToken, peerToken)
      : (peerToken, myToken)
    return shared.hkdfDerivedSymmetricKey(
      using: SHA256.self,
      salt: low + high,
      sharedInfo: pairDomain,
      outputByteCount: 32
    )
  }

  // MARK: - AEAD

  /// AES-256-GCM in the wire format `nonce(12) ‖ ciphertext ‖ tag(16)`.
  public static func seal(
    _ plaintext: Data,
    key: SymmetricKey,
    aad: Data,
    nonce: AES.GCM.Nonce = AES.GCM.Nonce()
  ) throws -> Data {
    // `combined` is only nil for non-12-byte nonces, which we never use.
    try AES.GCM.seal(plaintext, using: key, nonce: nonce, authenticating: aad).combined!
  }

  public static func open(_ sealed: Data, key: SymmetricKey, aad: Data) throws -> Data {
    try AES.GCM.open(AES.GCM.SealedBox(combined: sealed), using: key, authenticating: aad)
  }

  // MARK: - Presence

  public static func presenceAAD(lookupId: Data) -> Data {
    presenceDomain + lookupId
  }

  public static func sealPresence(
    _ card: NearbyPresenceCard,
    session: NearbySession,
    nonce: AES.GCM.Nonce = AES.GCM.Nonce()
  ) throws -> Data {
    try seal(
      JSONEncoder().encode(card),
      key: session.presenceKey,
      aad: presenceAAD(lookupId: session.lookupId),
      nonce: nonce
    )
  }

  /// Decrypts a presence heard as `token` and checks its key commitment.
  public static func openPresence(_ blob: Data, token: Data) throws -> (card: NearbyPresenceCard, publicKey: P256.KeyAgreement.PublicKey) {
    guard token.count == tokenLength else { throw NearbyCryptoError.malformedToken }
    let plaintext = try open(
      blob,
      key: presenceKey(for: token),
      aad: presenceAAD(lookupId: lookupId(for: token))
    )
    guard let card = try? JSONDecoder().decode(NearbyPresenceCard.self, from: plaintext),
          card.v == 1,
          let x963 = Data(base64URLEncoded: card.pub),
          let publicKey = try? P256.KeyAgreement.PublicKey(x963Representation: x963) else {
      throw NearbyCryptoError.malformedPresence
    }
    guard self.token(forPublicKey: publicKey.x963Representation) == token else {
      throw NearbyCryptoError.commitmentMismatch
    }
    return (card, publicKey)
  }

  // MARK: - Messages

  public static func headerAAD(recipientLookupId: Data) -> Data {
    headerDomain + recipientLookupId
  }

  public static func bodyAAD(recipientLookupId: Data, senderToken: Data) -> Data {
    bodyDomain + recipientLookupId + senderToken
  }
}

// MARK: - Encoding helpers

extension Data {
  init?(base64URLEncoded string: String) {
    var base64 = string
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
    self.init(base64Encoded: base64)
  }

  func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  init?(hexString: String) {
    guard hexString.count.isMultiple(of: 2) else { return nil }
    var bytes = [UInt8]()
    bytes.reserveCapacity(hexString.count / 2)
    var index = hexString.startIndex
    while index < hexString.endIndex {
      let next = hexString.index(index, offsetBy: 2)
      guard let byte = UInt8(hexString[index..<next], radix: 16) else { return nil }
      bytes.append(byte)
      index = next
    }
    self.init(bytes)
  }

  var hexString: String {
    map { String(format: "%02x", $0) }.joined()
  }
}

extension SymmetricKey {
  var data: Data {
    withUnsafeBytes { Data($0) }
  }
}
