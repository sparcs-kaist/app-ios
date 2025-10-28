//
//  TaxiRoomCreationViewModel.swift
//  soap
//
//  Created by 하정우 on 10/27/25.
//

import Foundation
import Factory
import BuddyDomain

@MainActor
@Observable
class TaxiRoomCreationViewModel {
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.taxiRoomRepository) private var taxiRoomRepository: TaxiRoomRepositoryProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  
  // MARK: - Properties
  var taxiUser: TaxiUser?
  var taxiRooms: (onGoing: [TaxiRoom], done: [TaxiRoom])?
  
  var hasUserPaid: Bool {
    guard let user = taxiUser else { return false }
    guard let room = taxiRooms else { return false }
    
    return user.hasUserPaid(room)
  }
  
  func fetchRoom() async throws {
    self.taxiUser = await userUseCase.taxiUser
    self.taxiRooms = try await taxiRoomRepository.fetchMyRooms()
  }
}
