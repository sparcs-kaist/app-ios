//
//  NearbyRelayRequestDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation

/// Binary fields are base64url without padding; lookup IDs are lowercase hex.
public struct NearbyPutPresenceRequestDTO: Encodable, Sendable {
  public let blob: String
}

public struct NearbyBatchGetRequestDTO: Encodable, Sendable {
  public let lookupIds: [String]
}

public struct NearbyPostMessageRequestDTO: Encodable, Sendable {
  public let header: String
  public let body: String
}
