//
//  ExamTime.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct ExamTime: Sendable, Codable {
  public let description: LocalizedString
  public let day: DayType
  public let begin: Int
  public let end: Int

  public var duration: Int {
    end - begin
  }

  public init(description: LocalizedString, day: DayType, begin: Int, end: Int) {
    self.description = description
    self.day = day
    self.begin = begin
    self.end = end
  }
}
