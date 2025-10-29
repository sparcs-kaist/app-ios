//
//  TaxiRoomUseCase.swift
//  BuddyData
//
//  Created by 하정우 on 10/29/25.
//

import Foundation
import BuddyDomain
import Factory

public final class TaxiRoomUseCase: TaxiRoomUseCaseProtocol {
  // MARK: - Dependencies
  private let taxiRoomRepository: TaxiRoomRepositoryProtocol
  private let userStorage: UserStorageProtocol
  
  // MARK: - Initializer
  public init(taxiRoomRepository: TaxiRoomRepositoryProtocol, userStorage: UserStorageProtocol) {
    self.taxiRoomRepository = taxiRoomRepository
    self.userStorage = userStorage
  }
  
  // MARK: - Functions
  public func isBlocked() async -> TaxiRoomBlockStatus {
    guard let taxiUser = await userStorage.getTaxiUser(),
          let taxiRooms = try? await taxiRoomRepository.fetchMyRooms().onGoing else {
      return .error(errorMessage: String(localized: "Failed to load user information."))
    }
    
    if !taxiUser.hasUserPaid(taxiRooms) {
      return .notPaid
    }
    
    if taxiRooms.count >= Constants.taxiMaxRoomCount {
      return .tooManyRooms
    }
    
    return .allow
  }
}
