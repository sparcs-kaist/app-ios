//
//  TaxiRoomEmojiIdentifier.swift
//  BuddyDomain
//
//  Created by 하정우 on 3/18/26.
//

import Foundation

public enum TaxiRoomEmojiIdentifier: String, Hashable, Codable, CaseIterable, Sendable {
  case apple
  case orange
  case lemon
  case watermelon
  case grape
  case strawberry
  case cherry
  case pineapple
  case kiwi
  case coconut
  case peach
  case banana
  case carrot
  case corn
  case broccoli
  case mushroom
  case unknown
  
  public var emoji: String {
    switch self {
    case .apple: "🍎"
    case .orange: "🍊"
    case .lemon: "🍋"
    case .watermelon: "🍉"
    case .grape: "🍇"
    case .strawberry: "🍓"
    case .cherry: "🍒"
    case .pineapple: "🍍"
    case .kiwi: "🥝"
    case .coconut: "🥥"
    case .peach: "🍑"
    case .banana: "🍌"
    case .carrot: "🥕"
    case .corn: "🌽"
    case .broccoli: "🥦"
    case .mushroom: "🍄"
    case .unknown: ""
    }
  }
}

