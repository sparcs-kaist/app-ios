//
//  TaxiSettingsViewState.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

import SwiftUI

public enum TaxiSettingsViewState: Equatable {
  case loading
  case loaded
  case error(message: LocalizedStringResource)
}
