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
  private let userStorage: UserStorageProtocol

  init(araUserRepository: AraUserRepositoryProtocol, taxiUserRepository: TaxiUserRepositoryProtocol, userStorage: UserStorageProtocol) {
    self.araUserRepository = araUserRepository
    self.taxiUserRepository = taxiUserRepository
    self.userStorage = userStorage
    logger.debug("Fetching Users")
    Task {
      await fetchUsers()
    }
  }

  var araUser: AraMe? {
    get async { await userStorage.getAraUser() }
  }
  
  var taxiUser: TaxiUser? {
    get async { await userStorage.getTaxiUser() }
  }

  func fetchUsers() async {
    do {
      try await fetchAraUser()
      try await fetchTaxiUser()
    } catch {
      logger.error(error)
    }
  }

  func fetchAraUser() async throws {
    logger.debug("Fetching Ara User")
    let user = try await araUserRepository.fetchMe()
    await userStorage.setAraUser(user)
    logger.debug(user)
  }
  
  func fetchTaxiUser() async throws {
    logger.debug("Fetching Taxi User")
    let user = try await taxiUserRepository.fetchUser()
    await userStorage.setTaxiUser(user)
    logger.debug(user)
  }
  
  func updateAraUser(allowNSFW: Bool, allowPolitical: Bool) async throws {
    logger.debug("Updating Ara User Visibility Setting")
    try await araUserRepository.updateVisibility(id: araUser?.id ?? -1, allowNSFW: allowNSFW, allowPolitical: allowPolitical)
  }
}
