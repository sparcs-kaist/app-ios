//
//  TaxiChatUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation
import UIKit

public protocol TaxiChatUseCaseProtocol: Sendable {
  /// A fresh multicast stream of the current chat list. Each call returns an
  /// independent subscriber stream; new subscribers immediately receive the
  /// latest known chats.
  func chatStream() async -> AsyncStream<[TaxiChat]>
  /// A fresh multicast stream of room updates.
  func roomUpdateStream() async -> AsyncStream<TaxiRoom>

  func setRoom(_ room: TaxiRoom) async
  func reconnect() async
  func fetchInitialChats() async
  func fetchChats(before date: Date) async
  func sendChat(_ content: String?, type: TaxiChat.ChatType) async
  func sendImage(_ content: UIImage) async throws
}
