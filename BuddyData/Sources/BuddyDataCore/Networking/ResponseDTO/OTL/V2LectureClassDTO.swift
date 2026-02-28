//
//  V2LectureClassDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 26/02/2026.
//

import Foundation
import BuddyDomain

public struct V2LectureClassDTO: Codable {
  public let day: Int
  public let begin: Int
  public let end: Int
  public let buildingCode: String
  public let buildingName: String
  public let roomName: String
}

public extension V2LectureClassDTO {
  func toModel() -> V2LectureClass {
    V2LectureClass(
      day: DayType(rawValue: day) ?? .sun,
      begin: begin,
      end: end,
      buildingCode: buildingCode,
      buildingName: buildingName,
      roomName: roomName
    )
  }
}
