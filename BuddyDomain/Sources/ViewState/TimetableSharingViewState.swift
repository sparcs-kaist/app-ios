//
//  TimetableSharingViewState.swift
//  BuddyDomain
//

import Foundation

public enum TimetableSharingViewState: Equatable {
  case loading
  case loaded(TimetableSharing)
  case error(message: String)
}
