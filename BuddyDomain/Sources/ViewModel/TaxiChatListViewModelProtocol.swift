//
//  TaxiChatListViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

@MainActor
public protocol TaxiChatListViewModelProtocol: Observable {
  // MARK: - ViewModel Properties
  var state: TaxiChatListViewState { get }
  var taxiUser: TaxiUser? { get }
  /// Unread chats by room ID. Rooms with none may be missing.
  var unreadCounts: [String: Int] { get }
  /// Unread chats across your rides, for the Chats button.
  var totalUnreadCount: Int { get }

  // MARK: - Functions
  func fetchData() async
}
