//
//  TimetableActivityAttributes.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if os(iOS)
import ActivityKit
import Foundation

/// The class Live Activity: one activity per run of back-to-back classes ("session").
///
/// The type name is part of the push payload (`attributes-type`), so it must not be renamed
/// once the server sends push-to-start requests.
public struct TimetableActivityAttributes: ActivityAttributes {
  public var sessionDate: String
  public var sessionNo: Int

  public init(sessionDate: String, sessionNo: Int) {
    self.sessionDate = sessionDate
    self.sessionNo = sessionNo
  }

  public struct ContentState: Codable, Hashable, Sendable {
    public var phase: Phase
    /// The class being counted down to, or in progress. In `.done`, the last class of the session.
    public var current: Item?
    public var next: NextItem?

    public init(phase: Phase, current: Item?, next: NextItem?) {
      self.phase = phase
      self.current = current
      self.next = next
    }
  }

  public enum Phase: String, Codable, Hashable, Sendable {
    /// Before or during `current`. Which of the two is decided at render time from `begin`
    /// and `isStale`, so the switch at class start needs no push.
    case upcoming
    case done
  }

  public enum Kind: String, Codable, Hashable, Sendable {
    case lecture
    case activity
  }

  /// Times are Unix seconds rather than `Date`: ActivityKit decodes `Date` as seconds since
  /// 2001, which silently shifts server-sent times by 31 years.
  public struct Item: Codable, Hashable, Sendable {
    public var title: String
    /// OTL's building code ("E11"), the part of the room students navigate by. Nil for custom
    /// blocks, whose place is free text in `buildingName`.
    public var buildingCode: String?
    public var buildingName: String
    public var room: String?
    public var kind: Kind
    /// `courseID` for a lecture, the activity id for a custom block. Turned into a colour on
    /// the device with the selected timetable theme, so no colour travels in the payload.
    public var colorID: Int
    public var begin: Int
    public var end: Int

    public init(
      title: String,
      buildingCode: String?,
      buildingName: String,
      room: String?,
      kind: Kind,
      colorID: Int,
      begin: Int,
      end: Int
    ) {
      self.title = title
      self.buildingCode = buildingCode
      self.buildingName = buildingName
      self.room = room
      self.kind = kind
      self.colorID = colorID
      self.begin = begin
      self.end = end
    }

    public var beginDate: Date { Date(timeIntervalSince1970: TimeInterval(begin)) }
    public var endDate: Date { Date(timeIntervalSince1970: TimeInterval(end)) }
  }

  public struct NextItem: Codable, Hashable, Sendable {
    public var title: String
    public var buildingCode: String?
    public var kind: Kind
    public var colorID: Int
    public var begin: Int

    public init(title: String, buildingCode: String?, kind: Kind, colorID: Int, begin: Int) {
      self.title = title
      self.buildingCode = buildingCode
      self.kind = kind
      self.colorID = colorID
      self.begin = begin
    }

    public var beginDate: Date { Date(timeIntervalSince1970: TimeInterval(begin)) }
  }
}
#endif
