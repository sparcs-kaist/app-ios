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
class TaxiChatViewModel: TaxiChatViewModelProtocol {
  enum ViewState {
    case loading
    case loaded(groupedChats: [TaxiChatGroup])
    case error(message: String)
  }
  // MARK: - Properties
  var state: ViewState = .loading
  var groupedChats: [TaxiChatGroup] = []
  var taxiUser: TaxiUser?
  var fetchedDateSet: Set<Date> = []
  var isUploading: Bool = false               // to show progress on image upload

  var room: TaxiRoom
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
        withAnimation(.spring) {
          self.state = .loaded(groupedChats: groupedChats)
        }
      }
      .store(in: &cancellables)

    taxiChatUseCase.roomUpdatePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] updatedRoom in
        guard let self = self else { return }
        self.room = updatedRoom
      }
      .store(in: &cancellables)
  }

  func fetchChats(before date: Date) async {
    if isFetching { return }
    isFetching = true
    defer { isFetching = false }
    
    await taxiChatUseCase.fetchChats(before: date)
  }

  func fetchInitialChats() async {
    await taxiChatUseCase.fetchInitialChats()
  }

  func sendChat(_ message: String, type: TaxiChat.ChatType) {
    if type == .text && message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

    Task {
      await taxiChatUseCase.sendChat(message, type: type)
    }
  }

  func leaveRoom() async throws {
    let _ = try await taxiRoomRepository.leaveRoom(id: room.id)
  }

  var isLeaveRoomAvailable: Bool {
    return !room.isDeparted
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

  var isCommitSettlementAvailable: Bool {
    return room.isDeparted && room.settlementTotal == 0
  }

  func commitPayment() {
    Task {
      do {
        let room: TaxiRoom = try await taxiRoomRepository.commitPayment(id: room.id)
        self.room = room
      } catch {
        logger.debug(error)
      }
    }
  }

  var isCommitPaymentAvailable: Bool {
    let me: TaxiParticipant? = room.participants.first(where: { $0.id == taxiUser?.oid})

    return room.isDeparted && room.settlementTotal != 0 && (
      me?.isSettlement == .paymentRequired
    )
  }

  func sendImage(_ image: UIImage) async throws {
    isUploading = true
    defer { isUploading = false }

    try await taxiChatUseCase.sendImage(image)
  }
}
