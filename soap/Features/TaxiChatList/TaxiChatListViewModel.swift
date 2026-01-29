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

@Observable
class TaxiChatListViewModel: TaxiChatListViewModelProtocol {
  enum ViewState {
    case loading
    case loaded(onGoing: [TaxiRoom], done: [TaxiRoom])
    case error(message: String)
  }
  // MARK: - ViewModel Properties
  var state: ViewState = .loading
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
