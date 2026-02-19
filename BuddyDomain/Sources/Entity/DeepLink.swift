//
//  DeepLink.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import Foundation

public extension Notification.Name {
  static let buddyInternalDeepLink = Notification.Name("buddyInternalDeepLink")
}

public enum DeepLink {
  case taxiInvite(code: String)
  case araPost(id: Int)

  public init?(url: URL) {
    switch url.host {
    case "taxi.sparcs.org":
      guard url.pathComponents.count == 3,
            url.pathComponents[1] == "invite" else {
        return nil
      }
      self = .taxiInvite(code: url.pathComponents[2])

    case "newara.sparcs.org":
      guard url.pathComponents.count == 3,
            url.pathComponents[1] == "post",
            let id = Int(url.pathComponents[2]) else {
        return nil
      }
      self = .araPost(id: id)

    default:
      return nil
    }
  }
}
