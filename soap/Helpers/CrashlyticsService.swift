//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics
import BuddyDomain

@Observable
final class CrashlyticsService: CrashlyticsServiceProtocol {
  func recordException(error: Error) {
    Crashlytics.crashlytics().record(error: error as NSError)
  }
}
