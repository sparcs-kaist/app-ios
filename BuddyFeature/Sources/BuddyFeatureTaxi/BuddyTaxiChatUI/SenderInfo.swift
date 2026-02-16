//
//  SenderInfo.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import Foundation

struct SenderInfo: Hashable {
  let id: String?
  let name: String?
  let avatarURL: URL?
  let isMine: Bool
  let isWithdrew: Bool
}
