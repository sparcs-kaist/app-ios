//
//  TimetableActivityPresentation.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if os(iOS)
import SwiftUI
import BuddyDomain

/// What the activity shows right now, worked out when the system renders it.
///
/// Countdown versus in-progress is decided here rather than sent by the server: each update
/// carries `stale-date = class begin`, and the system re-renders with `isStale` set when it
/// passes, so the switch at class start needs no push.
public struct TimetableActivityPresentation {
  public enum Mode: Equatable {
    case upcoming
    case inProgress
    case done
  }

  public let mode: Mode
  /// The last stretch of a class with another one after it: the next class is shown so the
  /// student knows where to head. Needs a push at that point (see the plan, §2).
  public let showsUpNext: Bool
  public let item: TimetableActivityAttributes.Item?
  public let next: TimetableActivityAttributes.NextItem?
  public let color: TimetableActivityColor
  public let nextColor: TimetableActivityColor?

  public init(
    state: TimetableActivityAttributes.ContentState,
    isStale: Bool,
    theme: TimetableTheme,
    now: Date = .now
  ) {
    item = state.current
    next = state.next

    switch (state.phase, state.current) {
    case (.upcoming, let current?):
      mode = (isStale || now >= current.beginDate) ? .inProgress : .upcoming
    default:
      mode = .done
    }

    showsUpNext = mode == .inProgress && state.next != nil
      && state.current.map { now >= $0.endDate.addingTimeInterval(-Self.upNextLead) } == true

    color = state.current.map { TimetableActivityColor(colorID: $0.colorID, theme: theme) } ?? .done
    nextColor = state.next.map { TimetableActivityColor(colorID: $0.colorID, theme: theme) }
  }

  /// How long before the end of a class the next one appears.
  public static let upNextLead: TimeInterval = 15 * 60

  /// The moment the big number counts down to.
  var countdownTarget: Date? {
    switch mode {
    case .upcoming: item?.beginDate
    case .inProgress: item?.endDate
    case .done: nil
    }
  }

  var symbol: String {
    switch (mode, item?.kind) {
    case (.done, _): "checkmark"
    case (_, .activity): "mappin"
    default: "book.closed.fill"
    }
  }
}

/// What both the current and the next class need to say where they are.
protocol TimetableActivityPlace {
  var buildingCode: String? { get }
  var buildingName: String { get }
  var room: String? { get }
}

extension TimetableActivityAttributes.Item: TimetableActivityPlace {}
extension TimetableActivityAttributes.NextItem: TimetableActivityPlace {}

extension TimetableActivityPlace {
  /// OTL names Korean buildings "(E11)창의학습관"; the code is shown on its own.
  var displayBuildingName: String {
    buildingName.replacing(/^\([^)]*\)\s*/, with: "")
  }

  /// "E11 101", the way students say a classroom. Custom blocks use their free-text place.
  var shortPlace: String {
    guard let buildingCode, !buildingCode.isEmpty else { return displayBuildingName }
    return [buildingCode, room].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
  }
}

extension TimetableActivityColor {
  static let done = TimetableActivityColor(fill: .green, onBlack: .green)
}
#endif
