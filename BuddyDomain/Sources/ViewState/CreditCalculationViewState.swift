//
//  CreditCalculationViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import SwiftUI

public enum CreditCalculationViewState: Equatable {
  case loading
  case loaded
  case error(message: String)
}
