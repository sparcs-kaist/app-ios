//
//  PostListType.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public enum PostListType: Sendable, Equatable {
  case all
  /// A board's posts, or only those under one of its topics.
  case board(boardID: Int, topicID: Int? = nil)
  case user(userID: Int)
  /// The most viewed posts of the past week, across boards.
  case trending
  /// A board's posts, by its slug, for when its id isn't known yet.
  case boardSlug(String)
  /// The newest posts across these boards.
  case latest(boardIDs: [Int])
}

