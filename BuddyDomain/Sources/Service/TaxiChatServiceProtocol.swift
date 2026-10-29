//
//  TaxiChatServiceProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 20/07/2025.
//

import Foundation

public protocol TaxiChatServiceProtocol: Sendable {
  /// A fresh multicast stream of the current chat list. Each call returns an
  /// independent subscriber stream.
  func chatStream() async -> AsyncStream<[TaxiChat]>
  /// A fresh multicast stream of socket connection state.
  func connectionStream() async -> AsyncStream<Bool>
  /// A fresh multicast stream of room IDs that received a `chat_update` event.
  func roomUpdateStream() async -> AsyncStream<String>
  /// A fresh multicast stream of chats as they are sent in any of your rooms, excluding older
  /// chats loaded for a room and minigame chats, which the app does not support.
  func liveChatStream() async -> AsyncStream<TaxiChat>
  func reconnect()
  func disconnect()
}
