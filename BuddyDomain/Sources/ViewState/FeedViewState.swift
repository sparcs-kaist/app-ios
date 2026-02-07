//
//  FeedViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/02/2026.
//

import SwiftUI

public enum FeedViewState: Equatable {
  case loading
  case loaded
  case error(message: String)
}
