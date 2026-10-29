//
//  TaxiQuickReplyUseCase.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 28/10/2026.
//

import Foundation
import BuddyDomain

public final class TaxiQuickReplyUseCase: TaxiQuickReplyUseCaseProtocol {
  private let taxiChatRepository: TaxiChatRepositoryProtocol?

  public init(taxiChatRepository: TaxiChatRepositoryProtocol?) {
    self.taxiChatRepository = taxiChatRepository
  }

  public func reply(_ text: String, roomID: String) async throws {
    guard let taxiChatRepository else { return }
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    try await taxiChatRepository.sendChat(TaxiChatRequest(roomID: roomID, type: .text, content: text))
    // Replying means you have read the room; failing to mark it only leaves its badge for now.
    try? await taxiChatRepository.readChats(roomID: roomID)
  }
}
