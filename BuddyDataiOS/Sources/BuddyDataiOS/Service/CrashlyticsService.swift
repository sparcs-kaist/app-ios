//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics
import BuddyDomain
import KeychainSwift

public final class CrashlyticsService: CrashlyticsServiceProtocol {
  private static let fcmDeviceIDKey: String = "fcmDeviceID"

  public func recordException(error: Error) {

    // Pass NetworkError those are not recordable
    if let networkError = error as? NetworkError,
       !networkError.isRecordable {
      return
    }

    let userID: String = getDeviceUUID()
    Crashlytics.crashlytics().record(error: error, userInfo: ["id": userID])
  }

  public func record(
    error: SourcedError,
    context: CrashContext
  ) {
    if let networkError = error as? NetworkError,
       !networkError.isRecordable {
      return
    }

    let userID: String = getDeviceUUID()

    let crashlytics = Crashlytics.crashlytics()

    crashlytics.setCustomValue(context.feature, forKey: "feature")
    crashlytics.setCustomValue(context.action, forKey: "action")
    crashlytics.setCustomValue(error.source.rawValue, forKey: "source")
    crashlytics.setCustomValue(userID, forKey: "user_id")

    context.metadata.forEach {
      crashlytics.setCustomValue($0.value, forKey: $0.key)
    }

    crashlytics.record(error: error)
  }

  public func record(
    error: Error,
    context: CrashContext
  ) {
    if let networkError = error as? NetworkError,
       !networkError.isRecordable {
      return
    }

    let userID: String = getDeviceUUID()

    let crashlytics = Crashlytics.crashlytics()

    crashlytics.setCustomValue(context.feature, forKey: "feature")
    crashlytics.setCustomValue(context.action, forKey: "action")
    crashlytics.setCustomValue(ErrorSource.unknown.rawValue, forKey: "source")
    crashlytics.setCustomValue(userID, forKey: "user_id")

    context.metadata.forEach {
      crashlytics.setCustomValue($0.value, forKey: $0.key)
    }

    crashlytics.record(error: error)
  }

  private func getDeviceUUID() -> String {
    let keychain = KeychainSwift()
    keychain.accessGroup = "N5V8W52U3U.org.sparcs.soap"

    return keychain.get(CrashlyticsService.fcmDeviceIDKey) ?? {
      let deviceUUID = UUID().uuidString
      keychain.set(deviceUUID, forKey: CrashlyticsService.fcmDeviceIDKey)

      return deviceUUID
    }()
  }
}
