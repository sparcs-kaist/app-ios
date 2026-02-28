//
//  V2TimetableDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

public struct V2TimetableDTO: Codable {
  public var lectures: [V2LectureDTO]
}

public extension V2TimetableDTO {
  func toModel(id: String) -> V2Timetable {
    V2Timetable(id: id, lectures: lectures.compactMap { $0.toModel() })
  }
}
