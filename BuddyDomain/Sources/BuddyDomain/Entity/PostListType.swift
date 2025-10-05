//
//  PostListType.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public enum PostListType: Sendable {
  case all
  case board(boardID: Int)
  case user(userID: Int)
}

