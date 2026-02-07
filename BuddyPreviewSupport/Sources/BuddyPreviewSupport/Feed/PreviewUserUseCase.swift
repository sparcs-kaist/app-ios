//
//  PreviewUserUseCase.swift
//  BuddyPreviewSupport
//

import Foundation
import BuddyDomain

public struct PreviewUserUseCase: UserUseCaseProtocol {
  public init() {}

  public var araUser: AraUser? { nil }
  public var taxiUser: TaxiUser? { nil }
  public var feedUser: FeedUser? {
    FeedUser(id: "preview", nickname: "PreviewUser", profileImageURL: nil, karma: 42)
  }
  public var otlUser: OTLUser? { nil }

  public func fetchUsers() async {}
  public func fetchAraUser() async throws {}
  public func fetchTaxiUser() async throws {}
  public func fetchFeedUser() async throws {}
  public func fetchOTLUser() async throws {}
  public func updateAraUser(params: [String: Any]) async throws {}
}
