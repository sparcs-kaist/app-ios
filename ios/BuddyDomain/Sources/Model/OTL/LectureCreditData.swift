//
//  LectureCreditData.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import Foundation

public struct LectureCreditData: Identifiable {
  public let lectureType: LectureType
  public let credits: Int
  public var id: String { lectureType.rawValue }

  public init(lectureType: LectureType, credits: Int) {
    self.lectureType = lectureType
    self.credits = credits
  }
}
