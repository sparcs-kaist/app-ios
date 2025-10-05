//
//  PostOrigin.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public enum PostOrigin: Sendable {
  case all
  case board
  case topic(topicID: String)
}

