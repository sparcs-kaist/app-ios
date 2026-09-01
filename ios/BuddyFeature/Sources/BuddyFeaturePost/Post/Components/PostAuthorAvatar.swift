//
//  PostAuthorAvatar.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import NukeUI
import BuddyFeatureShared

/// A circular author avatar (or a placeholder when no image URL is available).
struct PostAuthorAvatar: View {
  let url: URL?
  var size: CGFloat = 21

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
      .frame(width: size, height: size)
      .clipShape(.circle)
    } else {
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: size, height: size)
    }
  }
}
