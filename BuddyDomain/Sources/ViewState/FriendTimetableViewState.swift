//
//  FriendTimetableViewState.swift
//  BuddyDomain
//

import Foundation

public enum FriendTimetableViewState: Equatable {
  case loading
  case loaded(FriendTimetable)
  /// The friend has neither shared a timetable nor enrolled in any lectures.
  case empty
  case error(message: String)
}
