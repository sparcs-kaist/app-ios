//
//  TimetableSettingsViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation

public enum TimetableSettingsViewState: Equatable {
  case loading
  case loaded
  case error(message: String)
}
