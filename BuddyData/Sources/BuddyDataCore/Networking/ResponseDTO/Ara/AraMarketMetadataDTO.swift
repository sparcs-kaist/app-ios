//
//  AraMarketMetadataDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import BuddyDomain

/// A Market post's `metadata`, as the Ara web editor writes it. Other boards use the same
/// field for other things, so every key is optional and unknown ones are ignored.
struct AraMarketMetadataDTO: Codable {
  let price: Int?
  let priceCurrency: String?
  let state: String?

  enum CodingKeys: String, CodingKey {
    case price
    case priceCurrency = "price_currency"
    case state
  }

  init(price: Int?, priceCurrency: String?, state: String?) {
    self.price = price
    self.priceCurrency = priceCurrency
    self.state = state
  }

  init(from decoder: any Decoder) throws {
    guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
      price = nil
      priceCurrency = nil
      state = nil
      return
    }
    // Prices have been sent as numbers; tolerate a numeric string or a fraction too.
    if let price = try? container.decodeIfPresent(Int.self, forKey: .price) {
      self.price = price >= 0 ? price : nil
    } else if let price = try? container.decodeIfPresent(Double.self, forKey: .price) {
      self.price = Self.price(from: price)
    } else if let text = try? container.decodeIfPresent(String.self, forKey: .price) {
      self.price = Double(text.filter { ($0.isASCII && $0.isNumber) || $0 == "." || $0 == "-" })
        .flatMap(Self.price(from:))
    } else {
      self.price = nil
    }
    priceCurrency = try? container.decodeIfPresent(String.self, forKey: .priceCurrency)
    state = try? container.decodeIfPresent(String.self, forKey: .state)
  }

  /// `Int(_:)` traps on a value it can't hold, such as 1e300.
  private static func price(from value: Double) -> Int? {
    guard value >= 0 else { return nil }
    return Int(exactly: value.rounded(.towardZero))
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(price, forKey: .price)
    try container.encodeIfPresent(priceCurrency, forKey: .priceCurrency)
    try container.encodeIfPresent(state, forKey: .state)
  }

  /// `nil` when the metadata says nothing about selling.
  func toModel() -> AraMarketListing? {
    guard price != nil || state != nil else { return nil }
    return AraMarketListing(
      price: price,
      currency: priceCurrency ?? "KRW",
      state: state.flatMap(AraMarketListing.State.init(rawValue:)) ?? .onSale
    )
  }

  static func fromModel(_ listing: AraMarketListing) -> AraMarketMetadataDTO {
    AraMarketMetadataDTO(price: listing.price, priceCurrency: listing.currency, state: listing.state.rawValue)
  }
}
