//
//  NearbyRelayRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class NearbyRelayRepository: NearbyRelayRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<NearbyRelayTarget>

  public init(provider: MoyaProvider<NearbyRelayTarget>) {
    self.provider = provider
  }

  public func putPresence(lookupId: Data, blob: Data, ownerSecret: Data) async throws -> Date {
    let response = try await provider.request(.putPresence(
      lookupId: lookupId.hexString,
      request: NearbyPutPresenceRequestDTO(blob: blob.base64URLEncodedString()),
      ownerSecret: ownerSecret.base64URLEncodedString()
    ))
    let dto = try response.map(NearbyPresenceExpiryDTO.self)
    return Self.parseDate(dto.expiresAt) ?? Date().addingTimeInterval(300)
  }

  public func batchGet(lookupIds: [Data]) async throws -> [Data: Data] {
    guard !lookupIds.isEmpty else { return [:] }
    let response = try await provider.request(.batchGet(
      request: NearbyBatchGetRequestDTO(lookupIds: lookupIds.map(\.hexString))
    ))
    let dto = try response.map(NearbyBatchGetResponseDTO.self)
    var result: [Data: Data] = [:]
    for item in dto.items {
      guard let lookupId = Data(hexString: item.lookupId),
            let blob = Data(base64URLEncoded: item.blob) else { continue }
      result[lookupId] = blob
    }
    return result
  }

  public func deletePresence(lookupId: Data, ownerSecret: Data) async throws {
    _ = try await provider.request(.deletePresence(
      lookupId: lookupId.hexString,
      ownerSecret: ownerSecret.base64URLEncodedString()
    ))
  }

  public func postMessage(to lookupId: Data, header: Data, body: Data) async throws {
    _ = try await provider.request(.postMessage(
      lookupId: lookupId.hexString,
      request: NearbyPostMessageRequestDTO(
        header: header.base64URLEncodedString(),
        body: body.base64URLEncodedString()
      )
    ))
  }

  public func pollMessages(lookupId: Data, ownerSecret: Data, after: String?, wait: Int) async throws -> RelayMessagesPage {
    let response = try await provider.request(.pollMessages(
      lookupId: lookupId.hexString,
      ownerSecret: ownerSecret.base64URLEncodedString(),
      after: after,
      wait: wait
    ))
    return try response.map(NearbyMessagesPageDTO.self).toModel()
  }

  private static func parseDate(_ string: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: string)
  }
}
