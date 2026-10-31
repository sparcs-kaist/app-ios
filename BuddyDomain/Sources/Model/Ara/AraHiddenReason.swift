//
//  AraHiddenReason.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/10/2026.
//

import Foundation

extension AraPost {
  /// Hidden because the signed-in user blocked its author.
  public var isHiddenForBlockedAuthor: Bool {
    hiddenReason.contains(AraHiddenReason.blockedUserContent)
  }
}

extension AraPostComment {
  /// Hidden because the signed-in user blocked its author.
  public var isHiddenForBlockedAuthor: Bool {
    hiddenReason?.contains(AraHiddenReason.blockedUserContent) ?? false
  }
}

/// Values Ara sends in `why_hidden`.
public enum AraHiddenReason {
  public static let blockedUserContent = "BLOCKED_USER_CONTENT"
}
