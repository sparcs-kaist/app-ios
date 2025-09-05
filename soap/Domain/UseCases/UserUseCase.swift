//
//  UserUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Factory

final class UserUseCase: UserUseCaseProtocol {
  private let araUserRepository: AraUserRepositoryProtocol
  private let taxiUserRepository: TaxiUserRepositoryProtocol
  private let feedUserRepository: FeedUserRepositoryProtocol
  private let userStorage: UserStorageProtocol

  init(
    taxiUserRepository: TaxiUserRepositoryProtocol,
    feedUserRepository: FeedUserRepositoryProtocol,
    araUserRepository: AraUserRepositoryProtocol,
    userStorage: UserStorageProtocol
  ) {
    self.taxiUserRepository = taxiUserRepository
    self.feedUserRepository = feedUserRepository
    self.araUserRepository = araUserRepository
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

  func fetchUsers() async {
    do {
      async let taxiUserTask: () = fetchTaxiUser()
      async let feedUserTask: () = fetchFeedUser()
      async let araUserTask: () = fetchAraUser()
      _ = try await (taxiUserTask, feedUserTask, araUserTask)
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

  func updateAraUser(params: [String: Any]) async throws {
    logger.debug("Updating Ara User Information: \(params)")
    guard let araUser = await araUser else {
      logger.error("Ara User Not Found")
      return
    }
    try await araUserRepository.updateMe(id: araUser.id, params: params)
    try await fetchAraUser()
  }

  func fetchFeedUser() async throws {
    logger.debug("Fetching Feed User")
    let user = try await feedUserRepository.getUser()
    await userStorage.setFeedUser(user)
    logger.debug(user)
  }
}
