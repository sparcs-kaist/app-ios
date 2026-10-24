//
//  PostHeader.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// Title, metadata (date/views), and the tappable author row.
struct PostHeader: View {
  let title: AttributedString
  let createdAtText: String
  let views: Int
  let authorProfileURL: URL?
  let authorNickname: String
  let isAnonymous: Bool
  /// The price of a Market post, shown under its title.
  var marketListing: AraMarketListing? = nil
  let onAuthorTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)

      // Nothing to say about a listing without a price that's still for sale.
      if let marketListing, marketListing.price != nil || marketListing.state != .onSale {
        HStack(spacing: 8) {
          Text(marketListing.formattedPrice)
            .font(.title3.bold())
            .foregroundStyle(marketListing.price == nil || marketListing.state == .soldOut ? .secondary : .primary)
            .strikethrough(marketListing.state == .soldOut)
          if let label = marketListing.stateLabel {
            Text(label)
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(.fill.secondary, in: .capsule)
          }
        }
      }

      HStack {
        Text(createdAtText)
        Text("\(views) views", bundle: .module)
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      Button(action: onAuthorTapped) {
        HStack {
          PostAuthorAvatar(url: authorProfileURL, size: 28)

          Text(authorNickname)
            .fontWeight(.medium)

          if !isAnonymous {
            Image(systemName: "chevron.right")
          }
        }
        .font(.subheadline)
      }
      .tint(.primary)
      .disabled(isAnonymous)

      Divider()
        .padding(.vertical, 4)
    }
  }
}
