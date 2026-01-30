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
import BuddyDomain

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
  private var badgeByAuthorID: Dictionary<String, Bool>

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.taxiChatUseCase
  ) private var taxiChatUseCase: TaxiChatUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.taxiRoomRepository) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?

  // MARK: - Initialiser
  init(room: TaxiRoom) {
    self.room = room
    badgeByAuthorID = Dictionary(uniqueKeysWithValues: room.participants.map {
      ($0.id, $0.badge)
    })
  }

  func setup() async {
    guard let taxiChatUseCase else { return }
    await fetchTaxiUser()

    taxiChatUseCase.setRoom(self.room)

    bind()
  }

  private func fetchTaxiUser() async {
    guard let userUseCase else { return }
    
    self.taxiUser = await userUseCase.taxiUser
  }

  private func bind() {
    guard let taxiChatUseCase else { return }

    taxiChatUseCase.groupedChatsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] groupedChats in
        guard let self = self else { return }
        self.groupedChats = groupedChats
        self.groupedChats = self.groupedChats.map { groupedChat in
          var newGroupedChat = groupedChat
          
          newGroupedChat.chats = groupedChat.chats.filter { $0.roomID == self.room.id }
          return newGroupedChat
        }
        withAnimation(.spring) {
          self.state = .loaded(groupedChats: self.groupedChats)
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
    guard let taxiChatUseCase else { return }

    if isFetching { return }
    isFetching = true
    defer { isFetching = false }
    
    await taxiChatUseCase.fetchChats(before: date)
  }

  func fetchInitialChats() async {
    guard let taxiChatUseCase else { return }

    await taxiChatUseCase.fetchInitialChats()
  }

  func sendChat(_ message: String, type: TaxiChat.ChatType) {
    guard let taxiChatUseCase else { return }

    if type == .text && message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

    Task {
      await taxiChatUseCase.sendChat(message, type: type)
    }
  }

  func leaveRoom() async throws {
    guard let taxiRoomRepository else { return }
    let _ = try await taxiRoomRepository.leaveRoom(id: room.id)
  }

  var isLeaveRoomAvailable: Bool {
    return !room.isDeparted
  }

  func commitSettlement() {
    guard let taxiRoomRepository, let taxiChatUseCase else { return }

    Task {
      do {
        let room: TaxiRoom = try await taxiRoomRepository.commitSettlement(id: room.id)
        self.room = room

        guard let account = taxiUser?.account, !account.isEmpty else {
          return
        }
        await taxiChatUseCase.sendChat(account, type: .account)
      } catch {
        logger.debug(error)
      }
    }
  }

  var isCommitSettlementAvailable: Bool {
    return room.isDeparted && room.settlementTotal == 0
  }

  func commitPayment() {
    guard let taxiRoomRepository else { return }

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

  var account: String? {
    guard let paidParticiapnt = room.participants.first(where: { $0.isSettlement == .requestedSettlement }),
          let taxiChatUseCase else {
      return nil
    }

    return taxiChatUseCase.accountChats.last(where: { $0.authorID == paidParticiapnt.id })?.content
  }

  func sendImage(_ image: UIImage) async throws {
    guard let taxiChatUseCase else { return }

    isUploading = true
    defer { isUploading = false }

    try await taxiChatUseCase.sendImage(image)
  }
  
  func hasBadge(authorID: String?) -> Bool {
    guard let authorID else { return false }
    return badgeByAuthorID[authorID] ?? false
  }
}
