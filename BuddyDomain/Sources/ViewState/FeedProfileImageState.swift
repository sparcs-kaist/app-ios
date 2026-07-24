//
//  FeedProfileImageState.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/22/26.
//

import Foundation

public enum FeedProfileImageState: Equatable {
  case noChange
  case updated(image: PlatformImage)
  case removed
  case loading(progress: Progress)
  case error(message: String)

  public static func == (lhs: FeedProfileImageState, rhs: FeedProfileImageState) -> Bool {
    switch (lhs, rhs) {
    case (.noChange, .noChange), (.removed, .removed):
      return true
    // Compare images/progress by identity — avoids expensive pixel-by-pixel
    // comparison and lets the @Observable setter skip redundant invalidations.
    case let (.updated(l), .updated(r)):
      return l === r
    case let (.loading(l), .loading(r)):
      return l === r
    case let (.error(l), .error(r)):
      return l == r
    default:
      return false
    }
  }
}
