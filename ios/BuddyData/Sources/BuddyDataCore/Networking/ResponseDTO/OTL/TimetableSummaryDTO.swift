//
//  TimetableSummaryDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain

public struct TimetableSummaryDTO: Codable {
  public let id: Int
  public let name: String
  public let year: Int
  public let semester: Int
  public let timeTableOrder: Int
}


public extension TimetableSummaryDTO {
  func toModel() -> TimetableSummary {
    TimetableSummary(
      id: id,
      title: name,
      year: year,
      semester: SemesterType.fromRawValue(semester)
    )
  }
}
