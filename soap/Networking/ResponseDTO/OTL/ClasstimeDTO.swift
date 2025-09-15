//
//  ClasstimeDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation

struct ClasstimeDTO: Codable {
  let buildingCode: String
  let classroom: String
  let enClassroom: String
  let classroomShort: String
  let enClassroomShort: String
  let roomName: String
  let day: Int
  let begin: Int
  let end: Int

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
