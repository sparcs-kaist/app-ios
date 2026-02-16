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

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> UITableView {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = UITableView.automaticDimension
    tableView.dataSource = context.coordinator.dataSource(tableView: tableView)
    tableView.delegate = context.coordinator

    return tableView
  }

  func updateUIView(_ tableView: UITableView, context: Context) {
    context.coordinator.apply(items: items, animated: true)
  }

  final class Coordinator: NSObject, UITableViewDelegate {
    enum Section { case main }

    private var ds: UITableViewDiffableDataSource<Section, ChatRenderItem>?

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
          default:
            Text("test")
          }
        }
        .margins(.all, 0)

        return cell
      }

      self.ds = ds
      return ds
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

  ChatList(items: items)
    .ignoresSafeArea()
}
