//
//  TaxiChatRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation

public struct TaxiChatRequest {
  public let roomID: String
  public let type: TaxiChat.ChatType
  public let content: String?

  public init(roomID: String, type: TaxiChat.ChatType, content: String?) {
    self.roomID = roomID
    self.type = type
    self.content = content
  }
}
