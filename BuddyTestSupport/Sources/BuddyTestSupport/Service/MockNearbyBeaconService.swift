//
//  MockNearbyBeaconService.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import BuddyDomain

public final class MockNearbyBeaconService: NearbyBeaconServiceProtocol, @unchecked Sendable {
  public var authorization: NearbyBluetoothAuthorization = .allowed

  public private(set) var advertisedTokens: [Data] = []
  public private(set) var stopCallCount = 0
  /// The token being advertised right now, if any.
  public private(set) var currentToken: Data?
  private var continuation: AsyncThrowingStream<BeaconSighting, Error>.Continuation?

  public init() { }

  public func authorizationUpdates() -> AsyncStream<NearbyBluetoothAuthorization> {
    AsyncStream { continuation in
      continuation.yield(authorization)
      continuation.finish()
    }
  }

  public func start(advertising token: Data) -> AsyncThrowingStream<BeaconSighting, Error> {
    advertisedTokens.append(token)
    currentToken = token
    let (stream, continuation) = AsyncThrowingStream.makeStream(of: BeaconSighting.self)
    self.continuation = continuation
    return stream
  }

  public func stop() {
    stopCallCount += 1
    currentToken = nil
    continuation?.finish()
    continuation = nil
  }

  /// Delivers a sighting to the running stream.
  public func emit(_ sighting: BeaconSighting) {
    continuation?.yield(sighting)
  }
}
