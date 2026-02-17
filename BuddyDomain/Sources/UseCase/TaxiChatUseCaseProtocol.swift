//
//  TaxiChatUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation
import Combine
import UIKit

public protocol TaxiChatUseCaseProtocol: Sendable {
  var chatsPublisher: AnyPublisher<[TaxiChat], Never> { get }
  var roomUpdatePublisher: AnyPublisher<TaxiRoom, Never> { get }
  var accountChats: [TaxiChat] { get }

  func setRoom(_ room: TaxiRoom)
  func reconnect()
  func fetchInitialChats() async
  func fetchChats(before date: Date) async
  func sendChat(_ content: String?, type: TaxiChat.ChatType) async
  func sendImage(_ content: UIImage) async throws
}
