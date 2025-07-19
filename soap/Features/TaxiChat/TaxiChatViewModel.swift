//
//  TaxiChatViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import Observation
import Factory
import Combine

@MainActor
@Observable
class TaxiChatViewModel {
  // MARK: - Properties
  var groupedChats: [TaxiChatGroup] = []
  var taxiUser: TaxiUser?
  var fetchedDateSet: Set<Date> = []

  private var room: TaxiRoom
  private var cancellables = Set<AnyCancellable>()
  private var isFetching: Bool = false

  // MARK: - Dependencies
  private let taxiChatUseCase: TaxiChatUseCaseProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiRoomRepository) private var taxiRoomRepository: TaxiRoomRepositoryProtocol

  // MARK: - Initialiser
  init(room: TaxiRoom) {
    self.room = room
    taxiChatUseCase = Container.shared.taxiChatUseCase(room)

    bind()
    Task {
      await fetchTaxiUser()
    }
  }

  private func fetchTaxiUser() async {
    self.taxiUser = await userUseCase.taxiUser
  }

  private func bind() {
    taxiChatUseCase.groupedChatsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] groupedChats in
        guard let self = self else { return }
        self.groupedChats = groupedChats
      }
      .store(in: &cancellables)
  }

  func fetchChats(before date: Date) async {
    if isFetching { return }
    isFetching = true
    defer { isFetching = false }
    
    await taxiChatUseCase.fetchChats(before: date)
  }

  func sendChat(_ message: String, type: TaxiChat.ChatType) {
    if type == .text && message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

    Task {
      await taxiChatUseCase.sendChat(message, type: type)
    }
  }

  func commitSettlement() {
    Task {
      do {
        let room: TaxiRoom = try await taxiRoomRepository.commitSettlement(id: room.id)
        self.room = room
      } catch {
        logger.debug(error)
      }
    }
  }
}
