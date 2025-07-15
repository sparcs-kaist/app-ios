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

  var taxiUser: TaxiUser?

  init(taxiUserRepository: TaxiUserRepositoryProtocol) {
    self.taxiUserRepository = taxiUserRepository
    logger.debug("Fetching Users")
    Task {
      await fetchUsers()
    }
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
    taxiUser = user
    logger.debug(user)
  }
}
