//
//  ClassReminderRequestDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import Foundation

/// Body of `PUT /live-activity/devices/{device_uuid}`: everything the server needs to start and
/// update this device's class reminders on its own.
public struct ClassReminderDeviceRequestDTO: Encodable, Equatable, Sendable {
  public struct Slot: Encodable, Equatable, Sendable {
    public let id: String
    /// Monday = 0 … Sunday = 6, OTL's encoding.
    public let day: Int
    /// Minutes since midnight, Korean time.
    public let begin: Int
    public let end: Int
    public let title: String
    public let buildingCode: String?
    public let buildingName: String
    public let room: String?
    public let kind: String
    public let colorID: Int

    public init(
      id: String, day: Int, begin: Int, end: Int, title: String, buildingCode: String?,
      buildingName: String, room: String?, kind: String, colorID: Int
    ) {
      self.id = id
      self.day = day
      self.begin = begin
      self.end = end
      self.title = title
      self.buildingCode = buildingCode
      self.buildingName = buildingName
      self.room = room
      self.kind = kind
      self.colorID = colorID
    }

    enum CodingKeys: String, CodingKey {
      case id, day, begin, end, title, room, kind
      case buildingCode = "building_code"
      case buildingName = "building_name"
      case colorID = "color_id"
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(day, forKey: .day)
      try container.encode(begin, forKey: .begin)
      try container.encode(end, forKey: .end)
      try container.encode(title, forKey: .title)
      try container.encode(buildingCode, forKey: .buildingCode)
      try container.encode(buildingName, forKey: .buildingName)
      try container.encode(room, forKey: .room)
      try container.encode(kind, forKey: .kind)
      try container.encode(colorID, forKey: .colorID)
    }
  }

  public let mode: String
  public let liveActivitiesEnabled: Bool
  public let platform: String
  public let fcmToken: String?
  public let pushToStartToken: String?
  public let leadMinutes: Int
  public let includeCustomBlocks: Bool
  public let upNext: Bool
  public let sound: Bool
  public let year: Int?
  public let semester: Int?
  public let slots: [Slot]
  public let skipDates: [String]

  public init(
    mode: String, liveActivitiesEnabled: Bool, fcmToken: String?, pushToStartToken: String?,
    leadMinutes: Int, includeCustomBlocks: Bool, upNext: Bool, sound: Bool, year: Int?,
    semester: Int?, slots: [Slot], skipDates: [String]
  ) {
    self.mode = mode
    self.liveActivitiesEnabled = liveActivitiesEnabled
    self.platform = "ios"
    self.fcmToken = fcmToken
    self.pushToStartToken = pushToStartToken
    self.leadMinutes = leadMinutes
    self.includeCustomBlocks = includeCustomBlocks
    self.upNext = upNext
    self.sound = sound
    self.year = year
    self.semester = semester
    self.slots = slots
    self.skipDates = skipDates
  }

  enum CodingKeys: String, CodingKey {
    case mode, platform, sound, year, semester, slots
    case liveActivitiesEnabled = "live_activities_enabled"
    case fcmToken = "fcm_token"
    case pushToStartToken = "push_to_start_token"
    case leadMinutes = "lead_minutes"
    case includeCustomBlocks = "include_custom_blocks"
    case upNext = "up_next"
    case skipDates = "skip_dates"
  }

  // Explicit nulls rather than omitted keys, so the server can tell "no token" from "unchanged".
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(mode, forKey: .mode)
    try container.encode(liveActivitiesEnabled, forKey: .liveActivitiesEnabled)
    try container.encode(platform, forKey: .platform)
    try container.encode(fcmToken, forKey: .fcmToken)
    try container.encode(pushToStartToken, forKey: .pushToStartToken)
    try container.encode(leadMinutes, forKey: .leadMinutes)
    try container.encode(includeCustomBlocks, forKey: .includeCustomBlocks)
    try container.encode(upNext, forKey: .upNext)
    try container.encode(sound, forKey: .sound)
    try container.encode(year, forKey: .year)
    try container.encode(semester, forKey: .semester)
    try container.encode(slots, forKey: .slots)
    try container.encode(skipDates, forKey: .skipDates)
  }
}

/// Body of `PUT /live-activity/activities/{activity_id}`: a running activity's update token.
public struct ClassReminderActivityRequestDTO: Encodable, Sendable {
  public let deviceUUID: String
  public let updateToken: String
  public let sessionDate: String
  public let sessionNo: Int

  public init(deviceUUID: String, updateToken: String, sessionDate: String, sessionNo: Int) {
    self.deviceUUID = deviceUUID
    self.updateToken = updateToken
    self.sessionDate = sessionDate
    self.sessionNo = sessionNo
  }

  enum CodingKeys: String, CodingKey {
    case deviceUUID = "device_uuid"
    case updateToken = "update_token"
    case sessionDate = "session_date"
    case sessionNo = "session_no"
  }
}
