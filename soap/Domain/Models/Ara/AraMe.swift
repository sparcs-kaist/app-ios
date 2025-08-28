//
//  AraUser.swift
//  soap
//
//  Created by 하정우 on 8/19/25.
//

import Foundation

struct AraMe: Identifiable {
  let id: Int
  let nickname: String
  let nicknameUpdatedAt: Date?
  let allowNSFW: Bool
  let allowPolitical: Bool
}
