//
//  TaxiFavoriteRoute.swift
//  BuddyDomain
//

import Foundation

/// A route you starred in the Taxi tab, kept by the Taxi service with your account so it follows
/// you to every device and to the Taxi website. The two directions are separate routes.
public struct TaxiFavoriteRoute: Identifiable, Hashable, Sendable {
  /// The Taxi service's ID for the route, used to remove it.
  public let id: String
  public let sourceID: String
  public let destinationID: String
  public let createdAt: Date

  public init(id: String, sourceID: String, destinationID: String, createdAt: Date) {
    self.id = id
    self.sourceID = sourceID
    self.destinationID = destinationID
    self.createdAt = createdAt
  }
}
