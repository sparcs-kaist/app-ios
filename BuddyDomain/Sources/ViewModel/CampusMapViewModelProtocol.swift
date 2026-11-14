//
//  CampusMapViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI

@MainActor
public protocol CampusMapViewModelProtocol: Observable {
  var state: CampusMapViewState { get }
  var places: [CampusPlace] { get }
  var olevTimetable: OLEVTimetable { get }
  /// Pinned place IDs, in the order they were pinned.
  var pinnedPlaceIDs: [String] { get }
  var currentLatitude: Double { get }
  var currentLongitude: Double { get }

  func fetchPlaces() async
  func togglePin(_ place: CampusPlace)
  func cafeteriaMenu(for place: CampusPlace) -> CafeteriaMenu?
  func restaurantMenu(for place: CampusPlace) -> RestaurantMenu?
}
