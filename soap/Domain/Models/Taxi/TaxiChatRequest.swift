//
//  TaxiChatRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation

struct TaxiChatRequest {
  let roomID: String
  let type: TaxiChat.ChatType
  let content: String?
}
