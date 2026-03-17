//
//  MapDiscoveryViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/03/2026.
//

import SwiftUI
import Observation
import BuddyDomain

@MainActor
@Observable
class MapDiscoveryViewModel {
  var locations: [CampusLocation] = CampusLocation.mockList
  var selectedLocation: CampusLocation? = nil
}
