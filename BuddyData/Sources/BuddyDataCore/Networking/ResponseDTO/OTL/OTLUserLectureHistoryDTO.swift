//
//  OTLUserLectureHistoryDTO.swift
//  BuddyData
//

import Foundation
import BuddyDomain

struct OTLUserLectureHistoryDTO: Decodable {
  let lecturesWrap: [OTLUserLectureSemesterDTO]
  let reviewedLecturesCount: Int
  let totalLecturesCount: Int
  let totalLikesCount: Int
}

extension OTLUserLectureHistoryDTO {
  func toModel() -> OTLUserLectureHistory {
    OTLUserLectureHistory(
      semesters: lecturesWrap.map { $0.toModel() },
      totalLecturesCount: totalLecturesCount,
      reviewedLecturesCount: reviewedLecturesCount,
      totalLikesCount: totalLikesCount
    )
  }
}

private struct OTLUserLectureSemesterDTO: Decodable {
  let year: Int
  let semester: Int
  let lectures: [OTLTakenLectureDTO]
}

private extension OTLUserLectureSemesterDTO {
  func toModel() -> OTLUserLectureSemester {
    OTLUserLectureSemester(
      year: year,
      semesterType: SemesterType.fromRawValue(semester),
      lectures: lectures.map { $0.toModel() }
    )
  }
}

private struct OTLTakenLectureDTO: Decodable {
  let courseId: Int
  let lectureId: Int
  let name: String
  let code: String
  let professors: [ProfessorDTO]
  let written: Bool
}

private extension OTLTakenLectureDTO {
  func toModel() -> OTLTakenLecture {
    OTLTakenLecture(
      courseID: courseId,
      lectureID: lectureId,
      name: name,
      code: code,
      professors: professors.map { $0.toModel() },
      hasWrittenReview: written
    )
  }
}
