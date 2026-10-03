//
//  FriendsListViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

public enum FriendsListViewState: Equatable {
  case loading
  case loaded(friends: [Friend])
  case empty
  case error(message: String)
}
