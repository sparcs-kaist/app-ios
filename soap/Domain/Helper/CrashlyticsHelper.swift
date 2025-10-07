//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics
import Moya
import SwiftyBeaver

@MainActor
@Observable
final class CrashlyticsHelper {
  var showAlert: Bool = false
  
  func recordException(error: Error) {
    Crashlytics.crashlytics().record(error: error as NSError)
    showAlert = true
    logger.debug("recordException invoked; showAlert: \(showAlert)")
  }
}
