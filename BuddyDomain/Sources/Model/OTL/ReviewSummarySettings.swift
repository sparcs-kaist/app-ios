//
//  ReviewSummarySettings.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 11/10/2026.
//

import Foundation

/// Whether lecture and course pages summarise their reviews as soon as they
/// open, chosen in Settings. When off, a summary is written only on request.
public enum ReviewSummarySettings {
  /// The `UserDefaults.standard` key, shared by the setting and the review
  /// sections' `@AppStorage`.
  public static let automaticKey = "timetable.summarisesReviewsAutomatically"
  public static let automaticDefault = true
}
