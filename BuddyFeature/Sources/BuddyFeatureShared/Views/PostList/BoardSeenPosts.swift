//
//  BoardSeenPosts.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation

/// The newest post seen in each board's list, on this device. A board has new posts when its
/// newest is past that: seeing a post in the list counts, whether or not it was opened.
public enum BoardSeenPosts {
  private static let key = "BoardSeenNewestPostIDs"

  public static func newestSeen(inBoard boardID: Int) -> Int? {
    (UserDefaults.standard.dictionary(forKey: key) as? [String: Int])?[String(boardID)]
  }

  /// Records `postID` as seen in the board, unless a newer post already was.
  public static func markSeen(_ postID: Int, inBoard boardID: Int) {
    var seen = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
    guard postID > seen[String(boardID)] ?? .min else { return }
    seen[String(boardID)] = postID
    UserDefaults.standard.set(seen, forKey: key)
  }

  /// Forgets every board, so each shows a dot again while its newest post is unread.
  public static func reset() {
    UserDefaults.standard.removeObject(forKey: key)
  }
}
