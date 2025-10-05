//
//  ClassTime.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct ClassTime: Sendable {
  public let buildingCode: String
  public let classroomName: LocalizedString
  public let classroomNameShort: LocalizedString
  public let roomName: String
  public let day: DayType
  public let begin: Int
  public let end: Int

  public var duration: Int {
    end - begin
  }

  public init(
    buildingCode: String,
    classroomName: LocalizedString,
    classroomNameShort: LocalizedString,
    roomName: String,
    day: DayType,
    begin: Int,
    end: Int
  ) {
    self.buildingCode = buildingCode
    self.classroomName = classroomName
    self.classroomNameShort = classroomNameShort
    self.roomName = roomName
    self.day = day
    self.begin = begin
    self.end = end
  }
}
