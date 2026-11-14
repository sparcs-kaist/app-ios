//
//  CampusMapViewModelProtocol+Helpers.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation
import CoreLocation
import BuddyDomain

/// Read-only lookups every map variant shares, built on the protocol so preview doubles get them too.
extension CampusMapViewModelProtocol {
  var currentLocation: CLLocation {
    CLLocation(latitude: currentLatitude, longitude: currentLongitude)
  }

  var pinnedPlaces: [CampusPlace] {
    pinnedPlaceIDs.compactMap { id in places.first { $0.id == id } }
  }

  func isPinned(_ place: CampusPlace) -> Bool {
    pinnedPlaceIDs.contains(place.id)
  }

  func place(id: String) -> CampusPlace? {
    places.first { $0.id == id }
  }

  func distance(to place: CampusPlace) -> CLLocationDistance {
    currentLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
  }

  /// Places in the given categories, nearest first.
  func nearby(_ categories: Set<CampusPlaceCategory>? = nil, limit: Int = 10) -> [CampusPlace] {
    places
      .filter { categories?.contains($0.category) ?? true }
      .sorted { distance(to: $0) < distance(to: $1) }
      .prefix(limit)
      .map { $0 }
  }

  /// Matches names in either language, codes and keywords, so "카마", "N11" and "Kaimaru" all work.
  func search(_ query: String) -> [CampusPlace] {
    let query = query.trimmingCharacters(in: .whitespaces)
    guard !query.isEmpty else { return [] }
    return places
      .filter { place in
        ([place.name, place.nameKo, place.code ?? ""] + place.keywords)
          .contains { $0.localizedStandardContains(query) }
      }
      .sorted { distance(to: $0) < distance(to: $1) }
  }

  /// The building a facility sits in.
  func building(of place: CampusPlace) -> CampusPlace? {
    guard let code = place.buildingCode else { return nil }
    return places.first { $0.code == code }
  }

  /// Facilities inside a building, such as the restaurants in N11.
  func facilities(in place: CampusPlace) -> [CampusPlace] {
    guard let code = place.code else { return [] }
    return places.filter { $0.buildingCode == code }
  }

  /// The OLEV stop nearest to `place`, or to the user when `place` is nil.
  func nearestOLEVStop(to place: CampusPlace? = nil) -> CampusPlace? {
    let origin = place.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) } ?? currentLocation
    return places
      .filter { $0.category == .olevStop }
      .min {
        origin.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
          < origin.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
      }
  }

  /// What the map shows before any filter or search: everything except the shops and restaurants
  /// inside buildings, which the building's own marker stands for until the user narrows down.
  var landmarks: [CampusPlace] {
    places.filter { $0.buildingCode == nil }
  }

  var olevStops: [CampusPlace] {
    olevTimetable.stops.compactMap { place(id: $0.placeID) }
  }
}
