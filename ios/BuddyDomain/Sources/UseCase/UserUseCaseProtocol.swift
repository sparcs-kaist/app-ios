//
//  UserUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol UserUseCaseProtocol: Sendable {
  var araUser: AraUser? { get async }
  var taxiUser: TaxiUser? { get async }
  var feedUser: FeedUser? { get async }
  var otlUser: OTLUser? { get async }

  func fetchUsers() async
  func fetchAraUser() async throws
  func fetchTaxiUser() async throws
  func fetchFeedUser() async throws
  func fetchOTLUser() async throws
  func updateAraUser(params: [String: Any]) async throws
}
