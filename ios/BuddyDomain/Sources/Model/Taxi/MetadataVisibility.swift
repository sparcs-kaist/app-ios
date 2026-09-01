//
//  MetadataVisibility.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import Foundation

public struct MetadataVisibility: Hashable {
  public let showName: Bool
  public let showAvatar: Bool
  public let showTime: Bool

  public init(showName: Bool, showAvatar: Bool, showTime: Bool) {
    self.showName = showName
    self.showAvatar = showAvatar
    self.showTime = showTime
  }
}