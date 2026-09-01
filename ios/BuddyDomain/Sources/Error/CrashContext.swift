//
//  CrashContext.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/02/2026.
//

import Foundation

public struct CrashContext: Sendable {
  public let feature: String
  public let action: String
  public let metadata: [String: String]

  public init(
    feature: String,
    action: String = #function,
    metadata: [String: String] = [:]
  ) {
    self.feature = feature
    self.action = action
    self.metadata = metadata
  }
}
