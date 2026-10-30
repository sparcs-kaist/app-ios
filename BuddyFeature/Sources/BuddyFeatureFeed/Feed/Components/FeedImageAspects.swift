//
//  FeedImageAspects.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 31/10/2026.
//

import SwiftUI
import Nuke
import BuddyDomain

/// Aspect ratios of feed images, known before the rows that show them are built.
///
/// The feed's lazy stack discards rows as they scroll away and rebuilds them as they come back.
/// A row whose image hasn't loaded yet is laid out around a placeholder, and when the image arrives
/// in a different shape the row resizes. SwiftUI doesn't hold the visible rows still when one above
/// them resizes, so the feed jumped — most of all when scrolling back up past images whose loads
/// were cancelled on the way down. Loading each post's images as soon as the post arrives, and
/// sizing placeholders from the result, keeps every row at one height from its first layout.
@MainActor @Observable
final class FeedImageAspects {
  private var aspects: [String: CGFloat] = [:]
  @ObservationIgnored private var requested: Set<String> = []

  func aspect(for image: FeedImage) -> CGFloat? {
    aspects[image.id]
  }

  func record(_ size: CGSize, for image: FeedImage) {
    guard size.width > 0, size.height > 0, aspects[image.id] == nil else { return }
    aspects[image.id] = size.width / size.height
  }

  /// Starts loading the images of `posts` that haven't been asked for yet. The request matches the
  /// one `LazyImage` makes, so Nuke shares a load already in flight and keeps the result in its
  /// memory cache for the row.
  func prefetch(_ posts: [FeedPost]) {
    for image in posts.flatMap(\.images) where requested.insert(image.id).inserted {
      let request = ImageRequest(url: image.url, priority: .low)
      Task {
        guard let loaded = try? await ImagePipeline.shared.image(for: request) else { return }
        record(loaded.size, for: image)
      }
    }
  }
}
