//
//  TimetableDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

public struct TimetableDTO: Codable {
  public var lectures: [LectureDTO]
}

public extension TimetableDTO {
  func toModel(id: String) -> Timetable {
    Timetable(id: id, lectures: lectures.compactMap { $0.toModel() })
  }
}
