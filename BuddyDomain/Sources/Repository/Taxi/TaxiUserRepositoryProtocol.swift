//
//  TaxiUserRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiUserRepositoryProtocol: Sendable {
  func fetchUser() async throws -> TaxiUser
  func editBankAccount(account: String) async throws
  func registerPhoneNumber(phoneNumber: String) async throws
  func editBadge(showBadge: Bool) async throws
  func editNickname(nickname: String) async throws
  func registerResidence(residence: String) async throws
  func deleteResidence() async throws
  /// Your favourite routes, as the Taxi service keeps them for your account. Routes to or from a
  /// place that no longer exists are left out.
  func fetchFavoriteRoutes() async throws -> [TaxiFavoriteRoute]
  /// Saves a favourite route. Fails if the route is already saved.
  func createFavoriteRoute(sourceID: String, destinationID: String) async throws -> TaxiFavoriteRoute
  func deleteFavoriteRoute(id: String) async throws
}
