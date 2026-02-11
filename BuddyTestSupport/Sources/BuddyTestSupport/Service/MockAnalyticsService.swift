//
//  MockAnalyticsService.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import Foundation
import BuddyDomain

public final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
  public init() {}
  
  public func logEvent(_ event: any BuddyDomain.Event) {}
}
