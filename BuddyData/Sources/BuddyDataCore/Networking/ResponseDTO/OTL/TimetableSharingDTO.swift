//
//  TimetableSharingDTO.swift
//  BuddyData
//

import Foundation
import BuddyDomain

/// `GET /api/v2/timetables?year&semester`, read for its sharing flags. Kept apart from
/// `TimetableSummaryListDTO` so the cached `TimetableSummary` doesn't change shape.
struct TimetableSharingDTO: Decodable {
  struct Item: Decodable {
    let id: Int
    let name: String
    let year: Int
    let semester: Int
    let timeTableOrder: Int?
    let isShared: Bool?
  }

  let timetables: [Item]

  func toModel() -> TimetableSharing {
    let ordered = timetables.sorted { ($0.timeTableOrder ?? 0, $0.id) < ($1.timeTableOrder ?? 0, $1.id) }
    return TimetableSharing(
      timetables: ordered.map {
        TimetableSummary(id: $0.id, title: $0.name, year: $0.year, semester: .fromRawValue($0.semester))
      },
      sharedTimetableID: ordered.first { $0.isShared == true }?.id
    )
  }
}
