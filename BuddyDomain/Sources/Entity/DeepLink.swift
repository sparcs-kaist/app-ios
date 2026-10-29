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

/// A deep link raised before the main screen could observe it, e.g. by an App
/// Intent that launched the app. The main screen handles it once it appears.
@MainActor
public enum PendingDeepLink {
  public private(set) static var value: DeepLink?

  /// Hands `link` to the main screen, now if it's showing or when it appears.
  public static func post(_ link: DeepLink) {
    value = link
    NotificationCenter.default.post(name: .buddyInternalDeepLink, object: link)
  }

  /// The pending link, cleared so it is handled once.
  public static func take() -> DeepLink? {
    defer { value = nil }
    return value
  }
}

public enum DeepLink {
  case taxiInvite(code: String)
  /// The chat of a Taxi room you are in, such as from a chat notification.
  case taxiChat(roomID: String)
  case araPost(id: Int)
  case timetable

  public init?(url: URL) {
    let taxiBaseURL = Bundle.main.object(forInfoDictionaryKey: "TaxiBaseURL") as? String ?? "taxi.sparcs.org"
    let araBaseURL = Bundle.main.object(forInfoDictionaryKey: "AraBaseURL") as? String ?? "newara.sparcs.org"

    switch url.host {
    case taxiBaseURL:
      guard url.pathComponents.count == 3,
            url.pathComponents[1] == "invite" else {
        return nil
      }
      self = .taxiInvite(code: url.pathComponents[2])

    case araBaseURL:
      guard url.pathComponents.count == 3,
            url.pathComponents[1] == "post",
            let id = Int(url.pathComponents[2]) else {
        return nil
      }
      self = .araPost(id: id)

    case "timetable":
      self = .timetable

    default:
      return nil
    }
  }
}
