//
//  PreviewTaxiChatViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 3/7/26.
//

import Foundation
import BuddyDomain
import UIKit

public final class PreviewTaxiChatViewModel: TaxiChatViewModelProtocol {
  public var state: TaxiChatViewState
  public var renderItems: [ChatRenderItem] {
    Self.mockRenderItems
  }
  public var taxiUser: TaxiUser? = .mock
  public var room: TaxiRoom = .mock
  public var isUploading: Bool = false
  public var scrollToBottomTrigger: Int = 0
  public var alertState: AlertState?
  public var isAlertPresented: Bool = false
  public var isLeaveRoomAvailable: Bool = true
  public var isCommitSettlementAvailable: Bool = true
  public var isCommitPaymentAvailable: Bool = true
  public var account: String? = TaxiUser.mock.account
  public var topChatID: String?
  
  public init(state: TaxiChatViewState) {
    self.state = state
  }
  
  public func setup() async { }
  public func loadMoreChats() async { }
  public func fetchInitialChats() async { }
  public func sendChat(_ message: String, type: TaxiChat.ChatType) { }
  public func leaveRoom() async throws { }
  public func commitSettlement() { }
  public func commitPayment() { }
  public func sendImage(_ image: UIImage) async throws { }
}

private extension PreviewTaxiChatViewModel {
  static var mockRenderItems: [ChatRenderItem] {
    let chats = TaxiChat.mockList

    func sender(for chat: TaxiChat, isMine: Bool) -> SenderInfo {
      SenderInfo(
        id: chat.authorID,
        name: chat.authorName,
        avatarURL: chat.authorProfileURL,
        isMine: isMine,
        isWithdrew: chat.authorIsWithdrew ?? false
      )
    }

    func message(
      at index: Int,
      position: ChatBubblePosition,
      showName: Bool,
      showAvatar: Bool,
      showTime: Bool,
      isMine: Bool
    ) -> ChatRenderItem {
      let chat = chats[index]

      return .message(
        id: chat.id,
        chat: chat,
        kind: chat.type,
        sender: sender(for: chat, isMine: isMine),
        position: position,
        metadata: MetadataVisibility(
          showName: showName,
          showAvatar: showAvatar,
          showTime: showTime
        )
      )
    }

    return [
      .daySeparator(Calendar.current.startOfDay(for: chats[0].time)),
      .systemEvent(id: chats[0].id, chat: chats[0]),
      message(at: 1, position: .top, showName: false, showAvatar: false, showTime: false, isMine: true),
      message(at: 2, position: .middle, showName: false, showAvatar: false, showTime: false, isMine: true),
      message(at: 3, position: .bottom, showName: false, showAvatar: false, showTime: true, isMine: true),
      .systemEvent(id: chats[4].id, chat: chats[4]),
      message(at: 5, position: .single, showName: true, showAvatar: true, showTime: true, isMine: false),
      message(at: 6, position: .single, showName: false, showAvatar: true, showTime: true, isMine: true),
      message(at: 7, position: .single, showName: true, showAvatar: true, showTime: true, isMine: false),
      .systemEvent(id: chats[8].id, chat: chats[8]),
      message(at: 9, position: .single, showName: true, showAvatar: true, showTime: true, isMine: false),
      .systemEvent(id: chats[10].id, chat: chats[10]),
      message(at: 11, position: .single, showName: false, showAvatar: true, showTime: true, isMine: true),
      message(at: 12, position: .single, showName: false, showAvatar: false, showTime: true, isMine: false),
      message(at: 13, position: .single, showName: false, showAvatar: true, showTime: true, isMine: true),
      message(at: 14, position: .single, showName: true, showAvatar: true, showTime: true, isMine: false),
      message(at: 15, position: .single, showName: false, showAvatar: false, showTime: true, isMine: false),
      message(at: 16, position: .single, showName: false, showAvatar: false, showTime: true, isMine: false),
      message(at: 17, position: .single, showName: false, showAvatar: false, showTime: true, isMine: true),
      message(at: 18, position: .single, showName: true, showAvatar: true, showTime: true, isMine: false),
    ]
  }
}
