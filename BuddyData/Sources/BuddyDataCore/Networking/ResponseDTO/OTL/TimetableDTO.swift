//
//  TimetableDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

public struct TimetableDTO: Decodable {
  public var lectures: [LectureDTO]
  /// Absent from older responses; `my-timetable` always sends it empty.
  var customBlocks: [TimetableActivityDTO]?
}

public extension TimetableDTO {
  func toModel(id: String) -> Timetable {
    Timetable(
      id: id,
      lectures: lectures.compactMap { $0.toModel() },
      activities: (customBlocks ?? []).map { $0.toModel() }
    )
  }
}
