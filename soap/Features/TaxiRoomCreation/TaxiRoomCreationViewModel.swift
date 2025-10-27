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
  
  var isNotPaid: Bool {
    guard let user = taxiUser else { return true }
    guard let room = taxiRooms else { return true }
    
    // room.participants.first(where: { $0.id == taxiUser.oid })?.isSettlement ?? .notDeparted
    return !(room.onGoing.filter { room in
      room.participants.first(where: { $0.id == user.oid })?.isSettlement == .paymentRequired
    }.isEmpty)
  }
  
  // MARK: - Initializer
  init() {
    Task {
      self.taxiUser = await userUseCase.taxiUser
      self.taxiRooms = try? await taxiRoomRepository.fetchMyRooms()
    }
  }
}
