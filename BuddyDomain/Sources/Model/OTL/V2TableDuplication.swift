//
//  V2TableDuplication.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 15/09/2026.
//

import Foundation

/// The outcome of copying a timetable. The server has no copy endpoint, so a
/// duplicate is replayed item by item and individual rejections are reported
/// instead of failing the whole copy.
public struct TableDuplication: Identifiable, Sendable {
  public let id: Int
  public let skippedLectureCount: Int
  public let skippedActivityCount: Int

  public init(id: Int, skippedLectureCount: Int = 0, skippedActivityCount: Int = 0) {
    self.id = id
    self.skippedLectureCount = skippedLectureCount
    self.skippedActivityCount = skippedActivityCount
  }

  public var isComplete: Bool {
    skippedLectureCount == 0 && skippedActivityCount == 0
  }
}
