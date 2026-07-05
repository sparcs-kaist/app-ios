//
//  FeedAuthorAvatar.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI
import BuddyFeatureShared

/// The author's avatar (or a placeholder when no image URL is available).
struct FeedAuthorAvatar: View {
  let url: URL?

  var body: some View {
    if let url {
      LazyImage(url: url) { state in
        if let image = state.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Circle()
            .fill(Color.secondarySystemBackground)
        }
      }
      .frame(width: 24, height: 24)
      .clipShape(.circle)
    } else {
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: 24, height: 24)
        .overlay {
          Text("😀")
            .font(.caption)
        }
    }
  }
}
