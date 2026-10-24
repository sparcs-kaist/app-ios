//
//  PostListType.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public enum PostListType: Sendable {
  case all
  /// A board's posts, or only those under one of its topics.
  case board(boardID: Int, topicID: Int? = nil)
  case user(userID: Int)
}

