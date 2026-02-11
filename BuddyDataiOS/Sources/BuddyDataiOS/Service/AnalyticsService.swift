//
//  AnalyticsService.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 08/02/2026.
//

import Foundation
import FirebaseAnalytics
import KeychainSwift
import BuddyDomain

public class AnalyticsService: AnalyticsServiceProtocol {
  private static let fcmDeviceIDKey: String = "fcmDeviceID"

  public func logEvent(_ event: Event) {
    Analytics.setUserID(getDeviceUUID())
    Analytics.logEvent(event.name, parameters: event.parameters)
  }

  private func getDeviceUUID() -> String {
    let keychain = KeychainSwift()
    keychain.accessGroup = "N5V8W52U3U.org.sparcs.soap"

    return keychain.get(AnalyticsService.fcmDeviceIDKey) ?? {
      let deviceUUID = UUID().uuidString
      keychain.set(deviceUUID, forKey: AnalyticsService.fcmDeviceIDKey)

      return deviceUUID
    }()
  }
}
