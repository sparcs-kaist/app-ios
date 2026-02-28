//
//  V2TimetableSummaryDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain

public struct V2TimetableSummaryDTO: Codable {
  public let id: Int
  public let name: String
  public let year: Int
  public let semester: Int
  public let timeTableOrder: Int
}


public extension V2TimetableSummaryDTO {
  func toModel() -> V2TimetableSummary {
    V2TimetableSummary(
      id: id,
      name: name,
      year: year,
      semester: SemesterType.fromRawValue(semester)
    )
  }
}
