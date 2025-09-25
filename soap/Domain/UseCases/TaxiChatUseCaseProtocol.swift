//
//  TaxiChatUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 20/07/2025.
//

import Foundation
import Combine
import UIKit

@MainActor
protocol TaxiChatUseCaseProtocol {
  var groupedChatsPublisher: AnyPublisher<[TaxiChatGroup], Never> { get }
  var roomUpdatePublisher: AnyPublisher<TaxiRoom, Never> { get }
  var accountChats: [TaxiChat] { get }

  func fetchInitialChats() async
  func fetchChats(before date: Date) async
  func sendChat(_ content: String?, type: TaxiChat.ChatType) async
  func sendImage(_ content: UIImage) async throws
}
