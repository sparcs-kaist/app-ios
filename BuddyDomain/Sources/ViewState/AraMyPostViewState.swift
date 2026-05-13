//
//  AraMyPostViewState.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

public enum AraMyPostViewState: Equatable {
  case loading
  case loaded(posts: [AraPost])
  case error(message: String)
}
