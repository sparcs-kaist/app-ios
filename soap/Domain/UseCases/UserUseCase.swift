//
//  UserUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Factory

protocol UserUseCaseProtocol: Sendable {
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


final class UserUseCase: UserUseCaseProtocol {
  private let araUserRepository: AraUserRepositoryProtocol
  private let taxiUserRepository: TaxiUserRepositoryProtocol
  private let feedUserRepository: FeedUserRepositoryProtocol
  private let otlUserRepository: OTLUserRepositoryProtocol
  private let userStorage: UserStorageProtocol

  init(
    taxiUserRepository: TaxiUserRepositoryProtocol,
    feedUserRepository: FeedUserRepositoryProtocol,
    araUserRepository: AraUserRepositoryProtocol,
    otlUserRepository: OTLUserRepositoryProtocol,
    userStorage: UserStorageProtocol
  ) {
    self.taxiUserRepository = taxiUserRepository
    self.feedUserRepository = feedUserRepository
    self.araUserRepository = araUserRepository
    self.otlUserRepository = otlUserRepository
    self.userStorage = userStorage
    logger.debug("Fetching Users")
    Task {
      await fetchUsers()
    }
  }

  var araUser: AraUser? {
    get async { await userStorage.getAraUser() }
  }
  
  var taxiUser: TaxiUser? {
    get async { await userStorage.getTaxiUser() }
  }

  var feedUser: FeedUser? {
    get async { await userStorage.getFeedUser() }
  }

  var otlUser: OTLUser? {
    get async { await userStorage.getOTLUser() }
  }

  func fetchUsers() async {
    do {
      async let taxiUserTask: () = fetchTaxiUser()
      async let feedUserTask: () = fetchFeedUser()
      async let araUserTask: () = fetchAraUser()
      async let otlUserTask: () = fetchOTLUser()
      _ = try await (taxiUserTask, feedUserTask, araUserTask, otlUserTask)
    } catch {
      logger.error(error)
    }
  }

  func fetchAraUser() async throws {
    logger.debug("Fetching Ara User")
    let user = try await araUserRepository.fetchUser()
    await userStorage.setAraUser(user)
    logger.debug(user)
  }
  
  func fetchTaxiUser() async throws {
    logger.debug("Fetching Taxi User")
    let user = try await taxiUserRepository.fetchUser()
    await userStorage.setTaxiUser(user)
    logger.debug(user)
  }

  func fetchFeedUser() async throws {
    logger.debug("Fetching Feed User")
    let user = try await feedUserRepository.fetchUser()
    await userStorage.setFeedUser(user)
    logger.debug(user)
  }

  func fetchOTLUser() async throws {
    logger.debug("Fetching OTL User")
    let user = try await otlUserRepository.fetchUser()
    await userStorage.setOTLUser(user)
    logger.debug(user)
  }

  func updateAraUser(params: [String: Any]) async throws {
    logger.debug("Updating Ara User Information: \(params)")
    guard let araUser = await araUser else {
      logger.error("Ara User Not Found")
      return
    }
    try await araUserRepository.updateMe(id: araUser.id, params: params)
    try await fetchAraUser()
  }
}
