//
//  CreditSummarySnapshot.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import Foundation

/// The cumulative GPA and credits the app last computed, shared with the Credits
/// widget. The widget can't compute them itself: grades and edited minimums live
/// only in the app, and the lecture data takes many requests to load.
public struct CreditSummarySnapshot: Codable, Equatable, Sendable {
  public let gpa: Double?
  public let earnedCredits: Int
  public let graduationCredits: Int
  public let updatedAt: Date

  public init(gpa: Double?, earnedCredits: Int, graduationCredits: Int, updatedAt: Date = .now) {
    self.gpa = gpa
    self.earnedCredits = earnedCredits
    self.graduationCredits = graduationCredits
    self.updatedAt = updatedAt
  }

  /// Same values, ignoring when they were written.
  public func hasSameValues(as other: CreditSummarySnapshot) -> Bool {
    gpa == other.gpa && earnedCredits == other.earnedCredits && graduationCredits == other.graduationCredits
  }
}

/// Reads and writes the snapshot in the shared app group.
public struct CreditSummarySnapshotStore {
  /// The Credits widget's `kind`, for reloading its timelines.
  public static let widgetKind = "BuddyCreditsWidget"
  private static let key = "credits.summarySnapshot"

  private let defaults: UserDefaults

  public init(defaults: UserDefaults? = nil) {
    self.defaults = defaults ?? TimetableThemeStore.sharedDefaults
  }

  public var snapshot: CreditSummarySnapshot? {
    guard let data = defaults.data(forKey: Self.key) else { return nil }
    return try? JSONDecoder().decode(CreditSummarySnapshot.self, from: data)
  }

  public func save(_ snapshot: CreditSummarySnapshot) {
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    defaults.set(data, forKey: Self.key)
  }

  /// On sign-out, so the widget never shows a previous user's GPA.
  public func clear() {
    defaults.removeObject(forKey: Self.key)
  }
}
