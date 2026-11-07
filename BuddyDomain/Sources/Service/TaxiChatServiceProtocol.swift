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
  /// Reconnects with the current access token if the socket connected with another one, and
  /// returns once it's connected. Taxi sends a room's chats, when they're asked for, only to the
  /// socket that connected with the same token as the request.
  func connectWithCurrentAccessToken() async
  func reconnect()
  func disconnect()
}
