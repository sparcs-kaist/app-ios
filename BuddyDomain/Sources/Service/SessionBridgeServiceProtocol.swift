//
//  SessionBridgeServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation

public protocol SessionBridgeServiceProtocol {
  func start()
  func updateTimetable(_ timetable: Timetable)
  /// Pushes the theme currently selected in Settings so the watch follows it.
  func updateSelectedTheme()
  /// Pushes the Credits totals for the watch's Credits widget; nil clears them (sign-out).
  func updateCreditSummary(_ snapshot: CreditSummarySnapshot?)
}
