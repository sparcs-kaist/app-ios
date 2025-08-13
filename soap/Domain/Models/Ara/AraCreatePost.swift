//
//  AraCreatePost.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import Foundation

struct AraCreatePost {
  let title: String
  let content: String
  let attachments: [AraAttachment]
  let topic: AraBoardTopic?
  let isNSFW: Bool
  let isPolitical: Bool
  let nicknameType: AraPostNicknameType
  let board: AraBoard
}
