//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics

@Observable
final class CrashlyticsHelper {
  func recordException(error: Error) {
    Crashlytics.crashlytics().record(error: error as NSError)
  }
}
