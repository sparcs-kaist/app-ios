//
//  UserUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Factory

final class UserUseCase: UserUseCaseProtocol {
  private let taxiUserRepository: TaxiUserRepositoryProtocol
  private let feedUserRepository: FeedUserRepositoryProtocol
  private let userStorage: UserStorageProtocol

  init(
    taxiUserRepository: TaxiUserRepositoryProtocol,
    feedUserRepository: FeedUserRepositoryProtocol,
    userStorage: UserStorageProtocol
  ) {
    self.taxiUserRepository = taxiUserRepository
    self.feedUserRepository = feedUserRepository
    self.userStorage = userStorage
    logger.debug("Fetching Users")
    Task {
      await fetchUsers()
    }
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
      _ = try await (taxiUserTask, feedUserTask)
    } catch {
      logger.error(error)
    }
  }

  func fetchTaxiUser() async throws {
    logger.debug("Fetching Taxi User")
    let user = try await taxiUserRepository.fetchUser()
    await userStorage.setTaxiUser(user)
    logger.debug(user)
  }

  func fetchFeedUser() async throws {
    logger.debug("Fetching Feed User")
    let user = try await feedUserRepository.getUser()
    await userStorage.setFeedUser(user)
    logger.debug(user)
  }
}
