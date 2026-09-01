//
//  AnalyticsServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/02/2026.
//

import Foundation

public protocol AnalyticsServiceProtocol {
  func logEvent(_ event: Event)
}
