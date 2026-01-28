//
//  UserUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import BuddyDomain

public final class UserUseCase: UserUseCaseProtocol {
  private let araUserRepository: AraUserRepositoryProtocol?
  private let taxiUserRepository: TaxiUserRepositoryProtocol?
  private let feedUserRepository: FeedUserRepositoryProtocol?
  private let otlUserRepository: OTLUserRepositoryProtocol
  private let userStorage: UserStorageProtocol

  public init(
    taxiUserRepository: TaxiUserRepositoryProtocol?,
    feedUserRepository: FeedUserRepositoryProtocol?,
    araUserRepository: AraUserRepositoryProtocol?,
    otlUserRepository: OTLUserRepositoryProtocol,
    userStorage: UserStorageProtocol
  ) {
    self.taxiUserRepository = taxiUserRepository
    self.feedUserRepository = feedUserRepository
    self.araUserRepository = araUserRepository
    self.otlUserRepository = otlUserRepository
    self.userStorage = userStorage
    print("Fetching Users")
    Task {
      await fetchUsers()
    }
  }

  public var araUser: AraUser? {
    get async { await userStorage.getAraUser() }
  }
  
  public var taxiUser: TaxiUser? {
    get async { await userStorage.getTaxiUser() }
  }

  public var feedUser: FeedUser? {
    get async { await userStorage.getFeedUser() }
  }

  public var otlUser: OTLUser? {
    get async { await userStorage.getOTLUser() }
  }

  public func fetchUsers() async {
    do {
      async let taxiUserTask: () = fetchTaxiUser()
      async let feedUserTask: () = fetchFeedUser()
      async let araUserTask: () = fetchAraUser()
      async let otlUserTask: () = fetchOTLUser()
      _ = try await (taxiUserTask, feedUserTask, araUserTask, otlUserTask)
    } catch {
      print(error)
    }
  }

  public func fetchAraUser() async throws {
    guard let araUserRepository else { return }

    print("Fetching Ara User")
    let user = try await araUserRepository.fetchUser()
    await userStorage.setAraUser(user)
    print(user)
  }
  
  public func fetchTaxiUser() async throws {
    guard let taxiUserRepository else { return }
    
    print("Fetching Taxi User")
    let user = try await taxiUserRepository.fetchUser()
    await userStorage.setTaxiUser(user)
    print(user)
  }

  public func fetchFeedUser() async throws {
    guard let feedUserRepository else { return }
    
    print("Fetching Feed User")
    let user = try await feedUserRepository.fetchUser()
    await userStorage.setFeedUser(user)
    print(user)
  }

  public func fetchOTLUser() async throws {
    print("Fetching OTL User")
    let user = try await otlUserRepository.fetchUser()
    await userStorage.setOTLUser(user)
    print(user)
  }

  public func updateAraUser(params: [String: Any]) async throws {
    guard let araUserRepository else { return }
    
    print("Updating Ara User Information: \(params)")
    guard let araUser = await araUser else {
      print("Ara User Not Found")
      return
    }
    try await araUserRepository.updateMe(id: araUser.id, params: params)
    try await fetchAraUser()
  }
}
