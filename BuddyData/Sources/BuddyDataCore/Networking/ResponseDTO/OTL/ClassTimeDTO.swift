//
//  ClassTimeDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

public struct ClassTimeDTO: Codable {
  public let buildingCode: String
  public let classroom: String
  public let enClassroom: String
  public let classroomShort: String
  public let enClassroomShort: String
  public let roomName: String
  public let day: Int
  public let begin: Int
  public let end: Int

  enum CodingKeys: String, CodingKey {
    case buildingCode = "building_code"
    case classroom
    case enClassroom = "classroom_en"
    case classroomShort = "classroom_short"
    case enClassroomShort = "classroom_short_en"
    case roomName = "room_name"
    case day
    case begin
    case end
  }
}


public extension ClassTimeDTO {
  func toModel() -> ClassTime {
    ClassTime(
      buildingCode: buildingCode,
      classroomName: LocalizedString([
        "ko": classroom,
        "en": enClassroom
      ]),
      classroomNameShort: LocalizedString([
        "ko": classroomShort,
        "en": enClassroomShort
      ]),
      roomName: roomName,
      day: DayType(rawValue: day) ?? .sun,
      begin: begin,
      end: end
    )
  }
}
