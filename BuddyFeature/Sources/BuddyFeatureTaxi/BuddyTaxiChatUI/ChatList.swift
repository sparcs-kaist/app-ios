//
//  ChatList.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import SwiftUI
import UIKit
import BuddyDomain

struct ChatList: UIViewRepresentable {
  let items: [ChatRenderItem]
  let room: TaxiRoom
  let user: TaxiUser?

  func makeCoordinator() -> Coordinator {
    Coordinator(room: room, user: user)
  }

  func makeUIView(context: Context) -> UITableView {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = UITableView.automaticDimension
    tableView.dataSource = context.coordinator.dataSource(tableView: tableView)
    tableView.delegate = context.coordinator
    tableView.keyboardDismissMode = .interactive

    return tableView
  }

  func updateUIView(_ tableView: UITableView, context: Context) {
    context.coordinator.apply(items: items, animated: true)
  }

  final class Coordinator: NSObject, UITableViewDelegate {
    let room: TaxiRoom
    let user: TaxiUser?

    enum Section { case main }
    private var ds: UITableViewDiffableDataSource<Section, ChatRenderItem>?

    init(room: TaxiRoom, user: TaxiUser?) {
      self.room = room
      self.user = user
    }

    func dataSource(tableView: UITableView) -> UITableViewDiffableDataSource<Section, ChatRenderItem> {
      if let ds { return ds }

      let ds = UITableViewDiffableDataSource<Section, ChatRenderItem>(tableView: tableView) { tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        cell.contentConfiguration = UIHostingConfiguration {
          switch item {
          case .daySeparator(let date):
            ChatDaySeperator(date: date)
          case .systemEvent(_, let chat):
            ChatGeneralMessage(authorName: chat.authorName, type: chat.type)
          case .message(_, let chat, let kind, let sender, let position, let metadata):
            MessageView(
              chat: chat,
              kind: kind,
              sender: sender,
              position: position,
              readCount: self.readCount(for: chat),
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
                ChatAccountBubble(content: chat.content, isCommitPaymentAvailable: self.isCommitSettlementAvailable) {
                  // showPayMoneyAlert = true
                }
              case .share:
                ChatShareBubble(room: self.room)
              default:
                Text("not implemented")
              }
            }
          }
        }
        .margins(.all, 0)

        return cell
      }

      self.ds = ds
      return ds
    }

    private var isCommitSettlementAvailable: Bool {
      return room.isDeparted && room.settlementTotal == 0
    }

    private func readCount(for chat: TaxiChat) -> Int {
      let otherParticipants = self.room.participants.filter {
        $0.id != self.user?.oid
      }
      return otherParticipants.count(where: { $0.readAt <= chat.time })
    }

    func apply(items: [ChatRenderItem], animated: Bool) {
      guard let ds else { return }
      var snapshot = NSDiffableDataSourceSnapshot<Section, ChatRenderItem>()
      snapshot.appendSections([.main])
      snapshot.appendItems(items, toSection: .main)
      ds.apply(snapshot, animatingDifferences: animated)
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
  let items = builder.build(chats: mock, myUserID: "user1")

  ChatList(items: items, room: TaxiRoom.mock, user: TaxiUser.mock)
    .ignoresSafeArea()
}

