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
  private let userStorage: UserStorageProtocol

  init(taxiUserRepository: TaxiUserRepositoryProtocol, userStorage: UserStorageProtocol) {
    self.taxiUserRepository = taxiUserRepository
    self.userStorage = userStorage
    logger.debug("Fetching Users")
    Task {
      await fetchUsers()
    }
  }

  var taxiUser: TaxiUser? {
    get async { await userStorage.getTaxiUser() }
  }

  func fetchUsers() async {
    do {
      try await fetchTaxiUser()
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
  
  func taxiEditAccount(account: String) async {
    logger.debug("Updating Bank Account to \(account)")
    do {
      try await taxiUserRepository.editBankAccount(account: account)
    } catch {
      logger.debug(error)
    }
  }
  
  func fetchTaxiReports() async throws -> (reported: [TaxiReport], reporting: [TaxiReport]) {
    logger.debug("Fetching Taxi Reports")
    return try await taxiUserRepository.fetchReports()
  }
}
