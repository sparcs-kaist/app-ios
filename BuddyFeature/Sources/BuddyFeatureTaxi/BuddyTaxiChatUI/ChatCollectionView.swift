//
//  ChatCollectionView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/02/2026.
//

import Foundation
import SwiftUI
import BuddyDomain

/// Chat transcript list.
///
/// This used to be a `UICollectionView` bridged through `UIViewRepresentable`, with
/// every cell hosting a SwiftUI bubble via `UIHostingConfiguration` — so UIKit only
/// ever supplied the list container and scroll control. Both have direct SwiftUI
/// equivalents, and dropping the bridge is what lets this build on native macOS.
///
/// The initialiser is unchanged so `TaxiChatView` needs no edits.
struct ChatCollectionView: View {
  let items: [ChatRenderItem]
  let room: TaxiRoom
  let user: TaxiUser?
  let safeAreaInsets: EdgeInsets
  let scrollToBottomTrigger: Int

  /// Mirrors the old coordinator's `hasInitialScroll`: jump to the newest message
  /// once, then leave scrolling alone so paging back through history isn't yanked
  /// to the bottom.
  @State private var hasInitialScroll = false

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(items) { item in
            chatItem(item)
              .id(item.id)
          }
        }
      }
      .contentMargins(.top, safeAreaInsets.top, for: .scrollContent)
      .contentMargins(.bottom, safeAreaInsets.bottom + 8, for: .scrollContent)
      .scrollDismissesKeyboard(.interactively)
      .onAppear {
        scrollToBottomOnce(proxy)
      }
      .onChange(of: items) {
        scrollToBottomOnce(proxy)
      }
      .onChange(of: scrollToBottomTrigger) {
        scrollToBottom(proxy, animated: true)
      }
    }
  }

  // MARK: - Scrolling

  private func scrollToBottomOnce(_ proxy: ScrollViewProxy) {
    guard !hasInitialScroll, !items.isEmpty else { return }
    hasInitialScroll = true
    scrollToBottom(proxy, animated: false)
  }

  private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
    guard let lastID = items.last?.id else { return }

    // Defer a turn so the LazyVStack has laid out the newest rows before we scroll
    // to them — the UIKit version deferred through DispatchQueue.main.async here.
    Task { @MainActor in
      if animated {
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(lastID, anchor: .bottom)
        }
      } else {
        proxy.scrollTo(lastID, anchor: .bottom)
      }
    }
  }

  // MARK: - Rows

  @ViewBuilder
  private func chatItem(_ item: ChatRenderItem) -> some View {
    switch item {
    case .daySeparator(let date):
      ChatDaySeperator(date: date)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)

    case .systemEvent(_, let chat):
      ChatGeneralMessage(authorName: chat.authorName, type: chat.type)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)

    case .message(_, let chat, let kind, let sender, let position, let metadata):
      MessageView(
        chat: chat,
        kind: kind,
        sender: sender,
        position: position,
        readCount: readCount(for: chat),
        metadata: metadata
      ) {
        switch kind {
        case .text:
          ChatBubble(chat: chat, position: position, isMine: sender.isMine)
        case .s3img:
          ChatImageBubble(id: chat.content)
        case .departure:
          ChatDepartureBubble(room: self.room)
        case .arrival:
          ChatArrivalBubble()
        case .settlement:
          ChatSettlementBubble()
        case .payment:
          ChatPaymentBubble()
        case .account:
          ChatAccountBubble(content: chat.content, isCommitPaymentAvailable: self.isCommitSettlementAvailable) {}
        case .share:
          ChatShareBubble(room: self.room)
        default:
          Text("not supported", bundle: .module)
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, position == .middle || position == .bottom ? 4 : 8)
    }
  }

  private var isCommitSettlementAvailable: Bool {
    room.isDeparted && room.settlementTotal == 0
  }

  private func readCount(for chat: TaxiChat) -> Int {
    let otherParticipants = room.participants.filter { $0.id != user?.oid }
    return otherParticipants.count(where: { $0.readAt <= chat.time })
  }
}


#Preview {
  let mock: [TaxiChat] = TaxiChat.mockList
  let builder = ChatRenderItemBuilder(
    policy: TaxiGroupingPolicy(),
    positionResolver: ChatBubblePositionResolver(),
    presentationPolicy: DefaultMessagePresentationPolicy()
  )
  let items = builder.build(chats: mock, myUserID: "user2")

  ChatCollectionView(
    items: items,
    room: TaxiRoom.mock,
    user: TaxiUser.mock,
    safeAreaInsets: EdgeInsets(),
    scrollToBottomTrigger: 0
  )
    .ignoresSafeArea()
}
