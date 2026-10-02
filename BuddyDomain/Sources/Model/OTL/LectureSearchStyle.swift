//
//  LectureSearchStyle.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import Foundation

/// How the timetable's Add Lecture search opens, chosen in Settings.
public enum LectureSearchStyle: String, CaseIterable, Identifiable, Sendable {
  /// A sheet over the timetable, which stays visible and scrollable behind it.
  case sheet
  /// A pushed screen with the results across the whole view. On a compact screen the timetable
  /// is a preview a tap away; on a larger screen it sits beside the results.
  case fullScreen

  /// The `UserDefaults.standard` key, shared by the setting and the timetable's `@AppStorage`.
  public static let storageKey = "timetable.lectureSearchStyle"

  public var id: Self { self }
}
