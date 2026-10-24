//
//  AraPost+Display.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import BuddyDomain

extension AraPost {
  /// The title to show in a list, or why the post is hidden.
  public var listTitle: String {
    if isHidden {
      if isNSFW {
        return String(localized: "This post contains NSFW content", bundle: .module)
      }
      if isPolitical {
        return String(localized: "This post contains political content", bundle: .module)
      }
      return String(localized: "This post is hidden", bundle: .module)
    }
    return title ?? String(localized: "Untitled", bundle: .module)
  }
}

extension AraMarketListing {
  /// "₩20,000" (or "20,000원" in Korean), or "No Price" when the seller gave none.
  public var formattedPrice: String {
    guard let price else { return String(localized: "No Price", bundle: .module) }
    if price == 0 {
      return String(localized: "Free", bundle: .module)
    }
    guard currency == "KRW" else {
      return price.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }
    return String(localized: "₩\(price.formatted())", bundle: .module, comment: "A price in Korean won.")
  }

  /// "Reserved" or "Sold", or `nil` while still on sale.
  public var stateLabel: String? {
    switch state {
    case .onSale: nil
    case .reserved: String(localized: "Reserved", bundle: .module)
    case .soldOut: String(localized: "Sold", bundle: .module)
    }
  }
}
