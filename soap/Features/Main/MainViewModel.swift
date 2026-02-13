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
  var deepLinkedPost: AraPost? = nil
  var showInvalidInviteAlert: Bool = false
  var showInvalidPostAlert: Bool = false

  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol?

  func resolveInvite(code: String) async {
    guard let taxiRoomRepository else { return }

    do {
      invitedRoom = try await taxiRoomRepository.getPublicRoom(id: code)
    } catch {
      print(error)
      showInvalidInviteAlert = true
    }
  }

  func resolvePost(id: Int) async {
    guard let araBoardRepository else { return }

    do {
      deepLinkedPost = try await araBoardRepository.fetchPost(origin: nil, postID: id)
    } catch {
      print(error)
      showInvalidPostAlert = true
    }
  }
}

