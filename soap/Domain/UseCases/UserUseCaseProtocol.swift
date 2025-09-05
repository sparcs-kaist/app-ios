//
//  UserUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

protocol UserUseCaseProtocol: Sendable {
  var araUser: AraUser? { get async }
  var taxiUser: TaxiUser? { get async }
  var feedUser: FeedUser? { get async }

  func fetchUsers() async
  func fetchAraUser() async throws
  func fetchTaxiUser() async throws
  func updateAraUser(params: [String: Any]) async throws
  func fetchFeedUser() async throws
}
