//
//  PreviewCrashlyticsService.swift
//  BuddyPreviewSupport
//

import BuddyDomain

public struct PreviewCrashlyticsService: CrashlyticsServiceProtocol {
  public init() {}

  public func recordException(error: Error) {}
  public func record(error: SourcedError, context: CrashContext) {}
  public func record(error: Error, context: CrashContext) {}
}
