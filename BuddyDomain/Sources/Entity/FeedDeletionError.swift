//
//  FeedDeletionError.swift
//  BuddyDomain
//
//  Created by 하정우 on 1/17/26.
//

import Foundation

public enum FeedDeletionError: Error, LocalizedError {
  case hasComments
  
  public var errorDescription: String? {
    switch self {
    case .hasComments:
      String(localized: "Posts with comments cannot be deleted.")
    }
  }
}
