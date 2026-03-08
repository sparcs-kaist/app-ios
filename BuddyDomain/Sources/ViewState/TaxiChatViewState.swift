//
//  TaxiChatViewState.swift
//  BuddyDomain
//
//  Created by 하정우 on 07/03/2026.
//

import Foundation

public enum TaxiChatViewState {
  case loading
  case loaded
  case error(message: String)
}
