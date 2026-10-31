//
//  AraMarketListing.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation

/// What a Market (장터) post is selling for, from the post's metadata.
public struct AraMarketListing: Hashable, Sendable {
  public enum State: String, Sendable {
    case onSale = "onsale"
    case reserved
    case soldOut = "soldout"
  }

  /// In whole units of `currency`; `nil` when the seller gave none.
  public var price: Int?
  /// An ISO 4217 code, `KRW` unless the seller chose otherwise.
  public var currency: String
  public var state: State

  public init(price: Int?, currency: String = "KRW", state: State = .onSale) {
    self.price = price
    self.currency = currency
    self.state = state
  }
}

extension AraBoard {
  /// The Market board, whose posts are listings with a price.
  public static let marketSlug = "market"

  public var isMarket: Bool {
    slug == Self.marketSlug
  }
}
