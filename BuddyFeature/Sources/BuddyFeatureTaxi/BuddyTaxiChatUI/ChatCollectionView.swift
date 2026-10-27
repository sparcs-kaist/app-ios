//
//  ChatCollectionView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/02/2026.
//

import Foundation
import SwiftUI
import UIKit
import BuddyDomain

struct ChatCollectionView: UIViewRepresentable {
  @Environment(\.layoutDirection) private var layoutDirection

  let items: [ChatRenderItem]
  let room: TaxiRoom
  let user: TaxiUser?
  let isCommitPaymentAvailable: Bool
  let onCommitPayment: () -> Void
  let safeAreaInsets: EdgeInsets
  let scrollToBottomTrigger: Int
  /// Whether the rows run on under iPhone Duo's vertical bar, for when the bar holds nothing of
  /// the chat's, rather than stopping beside it.
  var runsUnderVerticalBar: Bool = false

  func makeUIView(context: Context) -> UICollectionView {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout(coordinator: context.coordinator))
    collectionView.backgroundColor = .clear
    collectionView.keyboardDismissMode = .interactive
    collectionView.topEdgeEffect.style = .soft
    collectionView.dataSource = context.coordinator
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    return collectionView
  }

  func updateUIView(_ collectionView: UICollectionView, context: Context) {
    let newBottomInset = self.safeAreaInsets.bottom + 8
    let oldBottomInset = context.coordinator.previousBottomInset
    // Read before the inset changes: shrinking it, as when the keyboard hides,
    // has the scroll view pull the offset back within the new range at once,
    // and shifting that offset by the change again would scroll the latest
    // messages down under the input bar.
    let offsetBeforeInsetChange = collectionView.contentOffset.y

    collectionView.contentInset.top = self.safeAreaInsets.top
    collectionView.contentInset.bottom = newBottomInset
    // Insets on the section keep the message rows inside the safe area while
    // the viewport extends under the side bars. Beside iPhone Duo's vertical
    // bar the rows either run on under it or come right up to it.
    let barEdge = Self.verticalBarEdge(of: collectionView)

    // The scroll indicator runs along the edge of the display under the bar,
    // whether or not the rows do: beside them it would cut through the
    // bubbles that run on under the bar, and look stranded short of the edge
    // when they stop beside it.
    let leadingIndicator = barEdge == .leading ? 0 : safeAreaInsets.leading
    let trailingIndicator = barEdge == .trailing ? 0 : safeAreaInsets.trailing
    var indicatorInsets = collectionView.contentInset
    indicatorInsets.left = layoutDirection == .rightToLeft ? trailingIndicator : leadingIndicator
    indicatorInsets.right = layoutDirection == .rightToLeft ? leadingIndicator : trailingIndicator
    collectionView.scrollIndicatorInsets = indicatorInsets

    let leadingInset = Self.inset(safeAreaInsets.leading, besideBar: barEdge == .leading, runsUnderBar: runsUnderVerticalBar)
    let trailingInset = Self.inset(safeAreaInsets.trailing, besideBar: barEdge == .trailing, runsUnderBar: runsUnderVerticalBar)
    if context.coordinator.leadingInset != leadingInset ||
       context.coordinator.trailingInset != trailingInset {
      context.coordinator.leadingInset = leadingInset
      context.coordinator.trailingInset = trailingInset
      collectionView.collectionViewLayout.invalidateLayout()
    }

    let insetDelta = newBottomInset - oldBottomInset

    // The bottom inset changes when the keyboard shows or hides. Shift the
    // content offset by the same amount so the messages that were on screen
    // stay exactly where they were, instead of being covered or jumping. The
    // offset is clamped to the valid scroll range to avoid over-scrolling when
    // the content is shorter than the viewport.
    if insetDelta != 0 {
      let minOffsetY = -self.safeAreaInsets.top
      let maxOffsetY = max(
        minOffsetY,
        collectionView.contentSize.height - collectionView.bounds.height + newBottomInset
      )
      let targetOffsetY = min(max(offsetBeforeInsetChange + insetDelta, minOffsetY), maxOffsetY)

      UIView.animate(
        withDuration: 0.25,
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState]
      ) {
        collectionView.contentOffset.y = targetOffsetY
        collectionView.layoutIfNeeded()
      }
    }

    context.coordinator.previousBottomInset = newBottomInset

    let oldItems = context.coordinator.items
    let shouldReload =
      oldItems != items ||
      context.coordinator.room != room ||
      context.coordinator.user != user ||
      context.coordinator.isCommitPaymentAvailable != isCommitPaymentAvailable

    context.coordinator.items = items
    context.coordinator.room = room
    context.coordinator.user = user
    context.coordinator.isCommitPaymentAvailable = isCommitPaymentAvailable
    context.coordinator.onCommitPayment = onCommitPayment

    if shouldReload {
      // Capture whether the user is pinned to the bottom *before* the reload
      // changes the content size, so we can preserve that position afterwards.
      let wasAtBottom = isAtBottom(collectionView)

      // Once the chat is on screen, rows are updated in place and new ones inserted rather than
      // every cell rebuilt, so what a row holds open, such as a rider's card, survives a message
      // arriving. A list that shrank or changed earlier on is reloaded whole.
      if context.coordinator.hasInitialScroll, items.count >= oldItems.count {
        let changed = oldItems.indices
          .filter { oldItems[$0] != items[$0] }
          .map { IndexPath(item: $0, section: 0) }
        let inserted = (oldItems.count..<items.count).map { IndexPath(item: $0, section: 0) }
        UIView.performWithoutAnimation {
          if !inserted.isEmpty {
            collectionView.insertItems(at: inserted)
          }
          // The rows that changed, and those on screen, which may draw from the room, the user or
          // the payment state.
          let visible = collectionView.indexPathsForVisibleItems.filter { $0.item < oldItems.count }
          let reconfigured = Set(changed + visible)
          if !reconfigured.isEmpty {
            collectionView.reconfigureItems(at: Array(reconfigured))
          }
        }
      } else {
        collectionView.reloadData()
      }

      if !context.coordinator.hasInitialScroll {
        context.coordinator.hasInitialScroll = true

        DispatchQueue.main.async {
          scrollToBottom(collectionView, animated: false)
        }
      } else if wasAtBottom {
        // A received message arrived while already scrolled to the bottom:
        // follow it. If the user had scrolled up to read history, stay put.
        DispatchQueue.main.async {
          scrollToBottom(collectionView, animated: true)
        }
      }
    }

    if scrollToBottomTrigger != context.coordinator.previousScrollTrigger {
      context.coordinator.previousScrollTrigger = scrollToBottomTrigger

      DispatchQueue.main.async {
        scrollToBottom(collectionView, animated: true)
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      items: items,
      room: room,
      user: user,
      isCommitPaymentAvailable: isCommitPaymentAvailable,
      onCommitPayment: onCommitPayment
    )
  }

  private func scrollToBottom(_ collectionView: UICollectionView, animated: Bool) {
    let itemCount = collectionView.numberOfItems(inSection: 0)
    guard itemCount > 0 else { return }

    let indexPath = IndexPath(item: itemCount - 1, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
  }

  /// Whether the collection view is scrolled to (or within `threshold` of) the
  /// bottom of its content, accounting for the adjusted content insets.
  private func isAtBottom(_ collectionView: UICollectionView, threshold: CGFloat = 60) -> Bool {
    let inset = collectionView.adjustedContentInset
    let visibleHeight = collectionView.bounds.height - inset.top - inset.bottom
    let contentHeight = collectionView.contentSize.height

    // Content shorter than the viewport is always effectively at the bottom.
    guard contentHeight > visibleHeight else { return true }

    let bottomEdge = collectionView.contentOffset.y + collectionView.bounds.height - inset.bottom
    return contentHeight - bottomEdge <= threshold
  }

  /// The horizontal padding of every row.
  static let rowPadding: CGFloat = 8

  /// The side the window's vertical bar is on, as on iPhone Duo, or `nil` where bars are
  /// horizontal.
  private static func verticalBarEdge(of view: UIView) -> HorizontalEdge? {
    guard #available(iOS 27.1, *) else { return nil }
    switch view.traitCollection.verticalBarEdge {
    case .leading: return .leading
    case .trailing: return .trailing
    default: return nil
    }
  }

  /// A side's section inset: its safe area, except beside iPhone Duo's vertical bar. There it is
  /// none when the rows run on under the bar, to the edge of the display with only their own
  /// padding, and otherwise the bar less that padding, so the bubbles come right up to it. Other
  /// insets, such as an iPhone's notch in landscape, keep the padding.
  private static func inset(_ safeArea: CGFloat, besideBar: Bool, runsUnderBar: Bool) -> CGFloat {
    guard besideBar else { return safeArea }
    if runsUnderBar { return 0 }
    return safeArea >= rowPadding ? safeArea - rowPadding : safeArea
  }

  private func layout(coordinator: Coordinator) -> UICollectionViewLayout {
    var config = UICollectionLayoutListConfiguration(appearance: .plain)
    config.showsSeparators = false
    return UICollectionViewCompositionalLayout { _, environment in
      let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
      section.contentInsets.leading = coordinator.leadingInset
      section.contentInsets.trailing = coordinator.trailingInset
      return section
    }
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject, UICollectionViewDataSource {
    var items: [ChatRenderItem]
    var room: TaxiRoom
    var user: TaxiUser?
    var isCommitPaymentAvailable: Bool
    var onCommitPayment: () -> Void
    var leadingInset: CGFloat = 0
    var trailingInset: CGFloat = 0
    var previousBottomInset: CGFloat = 0
    var previousScrollTrigger: Int = 0

    var hasInitialScroll = false
    private var badgeByAuthorID: Dictionary<String, Bool>

    init(
      items: [ChatRenderItem],
      room: TaxiRoom,
      user: TaxiUser?,
      isCommitPaymentAvailable: Bool,
      onCommitPayment: @escaping () -> Void
    ) {
      self.items = items
      self.room = room
      self.user = user
      self.isCommitPaymentAvailable = isCommitPaymentAvailable
      self.onCommitPayment = onCommitPayment
      badgeByAuthorID = Dictionary(uniqueKeysWithValues: room.participants.map {
        ($0.id, $0.badge)
      })
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
          metadata: metadata,
          rider: sender.isMine ? nil : room.participants.first { $0.id == sender.id }
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
            ChatSettlementBubble(content: chat.content)
          case .payment:
            ChatPaymentBubble()
          case .account:
            ChatAccountBubble(
              content: chat.content,
              isCommitPaymentAvailable: self.isCommitPaymentAvailable,
              markAsSent: self.onCommitPayment
            )
          case .share:
            ChatShareBubble(room: self.room)
          default:
            Text("not supported", bundle: .module)
          }
        }
        .padding(.horizontal, ChatCollectionView.rowPadding)
        .padding(.top, position == .middle || position == .bottom ? 4 : 8)
      }
    }

    private func readCount(for chat: TaxiChat) -> Int {
      let otherParticipants = room.participants.filter { $0.id != user?.oid }
      return otherParticipants.count(where: { $0.readAt <= chat.time })
    }

    private func safeAreaInsets(for view: UIView) -> UIEdgeInsets {
      view.safeAreaInsets
    }

    func hasBadge(authorID: String?) -> Bool {
      guard let authorID else { return false }
      return badgeByAuthorID[authorID] ?? false
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
    isCommitPaymentAvailable: false,
    onCommitPayment: {},
    safeAreaInsets: EdgeInsets(),
    scrollToBottomTrigger: 0
  )
    .ignoresSafeArea()
}
