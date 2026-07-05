//
//  TaxiChatListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiChatListViewModel")

@Observable
class TaxiChatListViewModel: TaxiChatListViewModelProtocol {
  // MARK: - ViewModel Properties
  var state: TaxiChatListViewState = .loading
  var onGoingRooms: [TaxiRoom] = []
  var doneRooms: [TaxiRoom] = []
  var taxiUser: TaxiUser?

  // MARK: - Dependency
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  // MARK: - Initialiser
  init() {
    Task {
      await fetchTaxiUser()
    }
  }

  // MARK: - Functions
  func fetchData() async {
    guard let taxiRoomRepository else { return }
    
    do {
      (onGoingRooms, doneRooms) = try await taxiRoomRepository.fetchMyRooms()
      withAnimation(.spring) {
        state = .loaded(onGoing: onGoingRooms, done: doneRooms)
      }
    } catch {
      logger.error("Failed to load taxi rooms: \(error.localizedDescription, privacy: .public)")
      withAnimation(.spring) {
        state = .error(message: error.localizedDescription)
      }
    }
  }

  private func fetchTaxiUser() async {
    guard let userUseCase else { return }
    
    self.taxiUser = await userUseCase.taxiUser
  }
}
