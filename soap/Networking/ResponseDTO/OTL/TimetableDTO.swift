//
//  TimetableDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

struct TimetableDTO: Codable {
  let id: Int
  var lectures: [LectureDTO]
}


extension TimetableDTO {
  func toModel() -> Timetable {
    Timetable(id: String(id), lectures: lectures.map { $0.toModel() })
  }
}
