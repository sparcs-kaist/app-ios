//
//  TaxiChatViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
class TaxiChatViewModel: TaxiChatViewModelProtocol {
  // MARK: - Properties
  var state: TaxiChatViewState = .loading
  var renderItems: [ChatRenderItem] = []
  var taxiUser: TaxiUser?
  var isUploading: Bool = false

  var scrollToBottomTrigger: Int = 0

  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false
  
  var isArrived: Bool = false
  var hasCarrier: Bool = false

  private(set) var topChatID: String? = nil
  private var fetchedDateSet: Set<Date> = []
  private var accountChats: [TaxiChat] = []

  var room: TaxiRoom
  @ObservationIgnored private var observationTasks: [Task<Void, Never>] = []
  private var isFetching: Bool = false

  private let renderItemBuilder = ChatRenderItemBuilder(
    policy: TaxiGroupingPolicy(),
    positionResolver: ChatBubblePositionResolver(),
    presentationPolicy: DefaultMessagePresentationPolicy()
  )

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.taxiChatUseCase
  ) private var taxiChatUseCase: TaxiChatUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.taxiRoomRepository) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?

  // MARK: - Initialiser
  init(room: TaxiRoom) {
    self.room = room
  }

  func setup() async {
    guard let taxiChatUseCase else { return }
    await fetchTaxiUser()

    await taxiChatUseCase.setRoom(self.room)

    await bind()
  }

  private func fetchTaxiUser() async {
    guard let userUseCase else { return }
    
    self.taxiUser = await userUseCase.taxiUser
  }

  private func bind() async {
    guard let taxiChatUseCase else { return }

    let chatStream = await taxiChatUseCase.chatStream()
    let roomUpdateStream = await taxiChatUseCase.roomUpdateStream()

    observationTasks.forEach { $0.cancel() }
    observationTasks = []

    observationTasks.append(Task { [weak self] in
      for await chats in chatStream {
        guard let self else { return }
        let filtered = chats.filter { $0.roomID == self.room.id }
        self.renderItems = self.renderItemBuilder.build(chats: filtered, myUserID: self.taxiUser?.oid)
        self.accountChats = chats.filter { $0.type == .account }
        self.state = .loaded
      }
    })

    observationTasks.append(Task { [weak self] in
      for await updatedRoom in roomUpdateStream {
        guard let self else { return }
        self.room = updatedRoom
      }
    })
  }

  deinit {
    observationTasks.forEach { $0.cancel() }
  }

  func loadMoreChats() async {
//    guard let taxiChatUseCase,
//          !isFetching,
//          let oldestDate = groupedChats.first?.chats.first?.time,
//          !fetchedDateSet.contains(oldestDate) else { return }
//
//    topChatID = groupedChats.first?.id
//    fetchedDateSet.insert(oldestDate)
//
//    isFetching = true
//    defer { isFetching = false }
//
//    await taxiChatUseCase.fetchChats(before: oldestDate)
  }

  func fetchInitialChats() async {
    guard let taxiChatUseCase else { return }
    
    isArrived = currentParticipant?.isArrived ?? false
    hasCarrier = currentParticipant?.hasCarrier ?? false

    await taxiChatUseCase.fetchInitialChats()
  }

  func sendChat(_ message: String, type: TaxiChat.ChatType) {
    guard let taxiChatUseCase else { return }

    if type == .text && message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

    scrollToBottomTrigger += 1

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

  var isArrivalToggleEnabled: Bool {
    room.departAt > Date()
  }
  
  var arrivedCount: Int {
    room.participants.filter(\.isArrived).count
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
        alertState = AlertState(title: "Error", message: error.localizedDescription)
        isAlertPresented = true
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
        alertState = AlertState(title: "Error", message: error.localizedDescription)
        isAlertPresented = true
      }
    }
  }

  var isCommitPaymentAvailable: Bool {
    let me: TaxiParticipant? = room.participants.first(where: { $0.id == taxiUser?.oid})

    return room.isDeparted && room.settlementTotal != 0 && (
      me?.isSettlement == .paymentRequired
    )
  }

  func updateArrival(isArrived: Bool) {
    guard let taxiRoomRepository else { return }

    Task {
      do {
        room = try await taxiRoomRepository.updateArrival(id: room.id, isArrived: isArrived)
      } catch {
        alertState = AlertState(title: "Error", message: error.localizedDescription)
        isAlertPresented = true
      }
    }
  }

  func updateCarrier(hasCarrier: Bool) {
    guard let taxiRoomRepository else { return }

    Task {
      do {
        room = try await taxiRoomRepository.updateCarrier(id: room.id, hasCarrier: hasCarrier)
      } catch {
        alertState = AlertState(title: "Error", message: error.localizedDescription)
        isAlertPresented = true
      }
    }
  }

  var account: String? {
    guard let paidParticiapnt = room.participants.first(where: { $0.isSettlement == .requestedSettlement }) else {
      return nil
    }

    return accountChats.last(where: { $0.authorID == paidParticiapnt.id })?.content
  }

  func sendImage(_ image: UIImage) async throws {
    guard let taxiChatUseCase else { return }

    scrollToBottomTrigger += 1

    isUploading = true
    defer { isUploading = false }

    try await taxiChatUseCase.sendImage(image)
  }

  private var currentParticipant: TaxiParticipant? {
    room.participants.first(where: { $0.id == taxiUser?.oid })
  }
}
