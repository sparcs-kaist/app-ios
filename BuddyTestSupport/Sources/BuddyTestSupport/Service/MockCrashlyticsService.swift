//
//  MockCrashlyticsService.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation
import BuddyDomain


public final class MockCrashlyticsService: CrashlyticsServiceProtocol, @unchecked Sendable {
  var recordExceptionCallCount = 0
  public var recordErrorWithContextCallCount = 0
  var lastRecordedError: Error?
  public var lastRecordedContext: CrashContext?

  public init() { }

  public func recordException(error: Error) {
    recordExceptionCallCount += 1
    lastRecordedError = error
  }

  public func record(error: SourcedError, context: CrashContext) {
    recordErrorWithContextCallCount += 1
    lastRecordedError = error
    lastRecordedContext = context
  }

  public func record(error: Error, context: CrashContext) {
    recordErrorWithContextCallCount += 1
    lastRecordedError = error
    lastRecordedContext = context
  }
}
