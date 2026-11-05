//
//  BackgroundActivity.swift
//  BuddyDataCore
//

import Foundation

/// Keeps the process running after the app leaves the foreground, until `end()`
/// or the system's deadline, whichever comes first. Works in apps and extensions.
public final class BackgroundActivity: Sendable {
  private let finished = DispatchSemaphore(value: 0)

  public init(reason: String) {
    ProcessInfo.processInfo.performExpiringActivity(withReason: reason) { [finished] expired in
      // Called a second time with `expired` when time runs out; release the first.
      if expired { finished.signal() } else { finished.wait() }
    }
  }

  public func end() { finished.signal() }
}
