//
//  V2LectureClass.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct V2LectureClass: Hashable, Sendable, Codable {
  public let day: DayType
  public let begin: Int
  public let end: Int
  public let buildingCode: String
  public let buildingName: String
  public let roomName: String

  public var duration: Int {
    end - begin
  }

  public init(
    day: DayType,
    begin: Int,
    end: Int,
    buildingCode: String,
    buildingName: String,
    roomName: String
  ) {
    self.day = day
    self.begin = begin
    self.end = end
    self.buildingCode = buildingCode
    self.buildingName = buildingName
    self.roomName = roomName
  }
}
