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
    case loaded
    case error(message: String)
  }
  // MARK: - Properties
  var state: ViewState = .loading
  var renderItems: [ChatRenderItem] = []
  var taxiUser: TaxiUser?
  var isUploading: Bool = false

  var scrollToBottomTrigger: Int = 0

  var alertState: AlertState? = nil
  var isAlertPresented: Bool = false

  private(set) var topChatID: String? = nil
  private var fetchedDateSet: Set<Date> = []

  var room: TaxiRoom
  private var cancellables = Set<AnyCancellable>()
  private var isFetching: Bool = false
  private var badgeByAuthorID: Dictionary<String, Bool>

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

    taxiChatUseCase.chatsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] chats in
        guard let self = self else { return }
        let filtered = chats.filter { $0.roomID == self.room.id }
        let builtItems = self.renderItemBuilder.build(chats: filtered, myUserID: self.taxiUser?.oid)
        self.renderItems = builtItems
        print("[HERE] \(self.renderItems)")
        self.state = .loaded
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

  var account: String? {
    guard let paidParticiapnt = room.participants.first(where: { $0.isSettlement == .requestedSettlement }),
          let taxiChatUseCase else {
      return nil
    }

    return taxiChatUseCase.accountChats.last(where: { $0.authorID == paidParticiapnt.id })?.content
  }

  func sendImage(_ image: UIImage) async throws {
    guard let taxiChatUseCase else { return }

    scrollToBottomTrigger += 1

    isUploading = true
    defer { isUploading = false }

    try await taxiChatUseCase.sendImage(image)
  }
  
  func hasBadge(authorID: String?) -> Bool {
    guard let authorID else { return false }
    return badgeByAuthorID[authorID] ?? false
  }
}
