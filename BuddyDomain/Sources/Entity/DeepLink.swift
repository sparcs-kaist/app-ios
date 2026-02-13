//
//  DeepLink.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import Foundation

public enum DeepLink {
  case taxiInvite(code: String)

  public init?(url: URL) {
    guard url.host == "taxi.sparcs.org",
          url.pathComponents.count == 3,
          url.pathComponents[1] == "invite" else {
      return nil
    }
    self = .taxiInvite(code: url.pathComponents[2])
  }
}
