//
//  MainViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import Foundation
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
final class MainViewModel {
  var invitedRoom: TaxiRoom? = nil
  var showInvalidInviteAlert: Bool = false

  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?

  func resolveInvite(code: String) async {
    guard let taxiRoomRepository else { return }

    do {
      invitedRoom = try await taxiRoomRepository.getPublicRoom(id: code)
    } catch {
      print(error)
      showInvalidInviteAlert = true
    }
  }
}

