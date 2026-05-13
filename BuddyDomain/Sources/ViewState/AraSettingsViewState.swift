//
//  AraSettingsViewState.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

public enum AraSettingsViewState: Equatable {
  case loading
  case loaded
  case error(message: String)
}
