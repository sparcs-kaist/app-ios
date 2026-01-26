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
public final class CrashlyticsService: CrashlyticsServiceProtocol {
  public init() { }
  
  public func recordException(error: Error) {
    Crashlytics.crashlytics().record(error: error as NSError)
  }
}
