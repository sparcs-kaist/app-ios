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
  @ObservationIgnored @Injected(\.taxiRoomUseCase) private var taxiRoomUseCase: TaxiRoomUseCaseProtocol
  
  // MARK: - Properties
  var blockStatus: TaxiRoomBlockStatus = .allow
  
  // MARK: - Functions
  func fetchBlockStatus() async {
    self.blockStatus = await taxiRoomUseCase.isBlocked()
  }
}
