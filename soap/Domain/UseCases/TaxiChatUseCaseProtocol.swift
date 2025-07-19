//
//  TaxiChatUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 20/07/2025.
//

import Foundation
import Combine

@MainActor
protocol TaxiChatUseCaseProtocol {
  var groupedChatsPublisher: AnyPublisher<[TaxiChatGroup], Never> { get }

  func fetchChats(before date: Date) async
}
