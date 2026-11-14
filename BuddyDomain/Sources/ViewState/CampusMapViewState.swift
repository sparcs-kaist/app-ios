//
//  CampusMapViewState.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI

public enum CampusMapViewState: Equatable {
  case loading
  case loaded
  case error(message: String)
}
