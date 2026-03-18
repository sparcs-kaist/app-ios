//
//  TaxiRoomEmojiIdentifier.swift
//  BuddyDomain
//
//  Created by 하정우 on 3/18/26.
//

import Foundation

public enum TaxiRoomEmojiIdentifier: String, Hashable, Codable, CaseIterable, Sendable {
  case apple = "🍎"
  case orange = "🍊"
  case lemon = "🍋"
  case watermelon = "🍉"
  case grape = "🍇"
  case strawberry = "🍓"
  case cherry = "🍒"
  case pineapple = "🍍"
  case kiwi = "🥝"
  case coconut = "🥥"
  case peach = "🍑"
  case banana = "🍌"
  case carrot = "🥕"
  case corn = "🌽"
  case broccoli = "🥦"
  case mushroom = "🍄"
  case unknown = ""
  
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let jsonString = try? container.decode(String.self)
    
    if let jsonString = jsonString, let matchedCase = Self.allCases.first(where: { String(describing: $0) == jsonString }) {
      self = matchedCase
    } else {
      self = .unknown
    }
  }
}

