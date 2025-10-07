//
//  CrashlyticsHelper.swift
//  soap
//
//  Created by 하정우 on 10/7/25.
//

import Foundation
import FirebaseCrashlytics
import Moya

protocol CrashlyticsHelperProtocol: Sendable {
  func recordException(error: Error)
}

final class CrashlyticsHelper: CrashlyticsHelperProtocol {
  func recordException(error: Error) {
    Crashlytics.crashlytics().record(error: error as NSError)
  }
}
