//
//  ChatCollectionView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/02/2026.
//

import SwiftUI
import UIKit
import BuddyDomain

struct ChatCollectionView: UIViewRepresentable {
  let items: [ChatRenderItem]
  let room: TaxiRoom
  let user: TaxiUser?
  let safeAreaInsets: EdgeInsets

  func makeUIView(context: Context) -> UICollectionView {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
    collectionView.backgroundColor = .clear
    collectionView.keyboardDismissMode = .interactive
    collectionView.dataSource = context.coordinator
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    return collectionView
  }

  func updateUIView(_ collectionView: UICollectionView, context: Context) {
    let newBottomInset = self.safeAreaInsets.bottom + 8
    let oldBottomInset = context.coordinator.previousBottomInset

    collectionView.contentInset.top = self.safeAreaInsets.top
    collectionView.contentInset.bottom = newBottomInset
    collectionView.scrollIndicatorInsets = collectionView.contentInset

    let delta = newBottomInset - oldBottomInset

    if delta > 0 {
      UIView.animate(
        withDuration: 0.25,
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState]
      ) {
        collectionView.contentOffset.y += delta
        collectionView.layoutIfNeeded()
      }
    }

    context.coordinator.previousBottomInset = newBottomInset

    let shouldReload =
      context.coordinator.items != items ||
      context.coordinator.room != room ||
      context.coordinator.user != user

    context.coordinator.items = items
    context.coordinator.room = room
    context.coordinator.user = user

    if shouldReload {
      collectionView.reloadData()

      if !context.coordinator.hasInitialScroll {
        context.coordinator.hasInitialScroll = true

        DispatchQueue.main.async {
          scrollToBottom(collectionView)
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(items: items, room: room, user: user)
  }

  private func scrollToBottom(_ collectionView: UICollectionView) {
    let itemCount = collectionView.numberOfItems(inSection: 0)
    guard itemCount > 0 else { return }

    let indexPath = IndexPath(item: itemCount - 1, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
  }

  private func layout() -> UICollectionViewLayout {
    var config = UICollectionLayoutListConfiguration(appearance: .plain)
    config.showsSeparators = false
    return UICollectionViewCompositionalLayout.list(using: config)
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject, UICollectionViewDataSource {
    var items: [ChatRenderItem]
    var room: TaxiRoom
    var user: TaxiUser?
    var previousBottomInset: CGFloat = 0

    var hasInitialScroll = false

    init(items: [ChatRenderItem], room: TaxiRoom, user: TaxiUser?) {
      self.items = items
      self.room = room
      self.user = user
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      // +2 for top and bottom safe-area spacer cells
      items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

      let item = items[indexPath.item]
      cell.contentConfiguration = UIHostingConfiguration {
        chatItem(item)
      }
      .margins(.all, 0)
      return cell
    }

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
            Text("not supported")
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

    private func safeAreaInsets(for view: UIView) -> UIEdgeInsets {
      view.safeAreaInsets
    }
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
    safeAreaInsets: EdgeInsets()
  )
    .ignoresSafeArea()
}
