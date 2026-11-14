//
//  CampusMapViewModel.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation
import Observation
import BuddyDomain

/// Serves the map from mock data until the locations API lands; nothing here talks to a server.
@MainActor
@Observable
public final class CampusMapViewModel: CampusMapViewModelProtocol {
  // MARK: - Properties
  public var state: CampusMapViewState = .loading
  public var places: [CampusPlace] = []
  public var olevTimetable: OLEVTimetable = .mock
  public var pinnedPlaceIDs: [String] = ["N11", "OV3", "wellchai", "tom-n-toms"]
  public let currentLatitude: Double = CampusPlace.mockCurrentLatitude
  public let currentLongitude: Double = CampusPlace.mockCurrentLongitude

  @ObservationIgnored private let cafeteriaMenus = CafeteriaMenu.mockList
  @ObservationIgnored private let restaurantMenus = RestaurantMenu.mockList

  public init() {}

  // MARK: - Functions
  public func fetchPlaces() async {
    places = CampusPlace.mockList
    state = .loaded
  }

  public func togglePin(_ place: CampusPlace) {
    if let index = pinnedPlaceIDs.firstIndex(of: place.id) {
      pinnedPlaceIDs.remove(at: index)
    } else {
      pinnedPlaceIDs.append(place.id)
    }
  }

  public func cafeteriaMenu(for place: CampusPlace) -> CafeteriaMenu? {
    cafeteriaMenus.first { $0.placeID == place.id }
  }

  public func restaurantMenu(for place: CampusPlace) -> RestaurantMenu? {
    restaurantMenus.first { $0.placeID == place.id }
  }
}
