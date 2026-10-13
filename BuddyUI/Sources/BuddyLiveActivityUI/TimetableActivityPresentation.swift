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

    color = state.current.map { TimetableActivityColor(colorID: $0.colorID, theme: theme) } ?? .done
    nextColor = state.next.map { TimetableActivityColor(colorID: $0.colorID, theme: theme) }
  }

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

extension TimetableActivityAttributes.Item {
  /// OTL names Korean buildings "(E11)창의학습관"; the code already has its own badge.
  var displayBuildingName: String {
    buildingName.replacing(/^\([^)]*\)\s*/, with: "")
  }
}

extension TimetableActivityColor {
  static let done = TimetableActivityColor(fill: .green, onBlack: .green)
}
#endif
