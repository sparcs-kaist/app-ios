//
//  PostListViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation

public enum PostListViewState: Equatable {
  case loading
  case loaded(posts: [AraPost])
  case error(message: String)
}

