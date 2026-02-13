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
  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false

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
      alertState = .init(
        title: String(localized: "Invalid Invitation"),
        message: String(localized: "The link you followed is invalid. Please try again.")
      )
      isAlertPresented = true
    }
  }

  func resolvePost(id: Int) async {
    guard let araBoardRepository else { return }

    do {
      deepLinkedPost = try await araBoardRepository.fetchPost(origin: nil, postID: id)
    } catch {
      alertState = .init(
        title: String(localized: "Post Not Found"),
        message: String(localized: "The post you are looking for could not be found.")
      )
      isAlertPresented = true
    }
  }
}

