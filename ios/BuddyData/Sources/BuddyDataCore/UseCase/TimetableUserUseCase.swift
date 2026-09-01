//
//  TimetableUserUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation
import BuddyDomain

public final class TimetableUserUseCase: UserUseCaseProtocol {
  public var araUser: AraUser? { nil }
  public var taxiUser: TaxiUser? { nil }
  public var feedUser: FeedUser? { nil }
  public var otlUser: OTLUser? {
    get async { try? await otlUserRepository.fetchUser() }
  }

  private let otlUserRepository: OTLUserRepositoryProtocol

  public init(otlUserRepository: OTLUserRepositoryProtocol) {
    self.otlUserRepository = otlUserRepository
  }

  public func getOTLUser() async -> OTLUser? {
    return try? await otlUserRepository.fetchUser()
  }

  // MARK: - UserUseCaseProtocol
  public func fetchUsers() async {

  }

  public func fetchAraUser() async throws {

  }

  public func fetchTaxiUser() async throws {

  }

  public func fetchFeedUser() async throws {

  }

  public func fetchOTLUser() async throws {
    
  }

  public func updateAraUser(params: [String : Any]) async throws {

  }


}
