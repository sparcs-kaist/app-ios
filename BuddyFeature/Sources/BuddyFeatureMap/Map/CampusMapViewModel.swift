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
  private var reviewsByPlaceID = Dictionary(grouping: PlaceReview.mockList, by: \.placeID)

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

  public func reviews(for place: CampusPlace) -> [PlaceReview] {
    (reviewsByPlaceID[place.id] ?? []).sorted { $0.createdAt > $1.createdAt }
  }

  public func toggleUpvote(_ review: PlaceReview) {
    guard let index = reviewsByPlaceID[review.placeID]?.firstIndex(where: { $0.id == review.id }) else { return }
    let isUpvoted = !review.isUpvoted
    reviewsByPlaceID[review.placeID]?[index].isUpvoted = isUpvoted
    reviewsByPlaceID[review.placeID]?[index].upvotes += isUpvoted ? 1 : -1
  }

  public func writeReview(for place: CampusPlace, rating: Int, text: String, photos: [PlacePhoto]) {
    var reviews = reviewsByPlaceID[place.id] ?? []
    let existing = reviews.firstIndex(where: \.isMine)
    let review = PlaceReview(
      id: existing.map { reviews[$0].id } ?? UUID().uuidString,
      placeID: place.id,
      authorName: String(localized: "You", bundle: .module),
      rating: min(max(rating, 1), 5),
      text: text.trimmingCharacters(in: .whitespacesAndNewlines),
      createdAt: .now,
      photos: photos,
      upvotes: existing.map { reviews[$0].upvotes } ?? 0,
      isUpvoted: existing.map { reviews[$0].isUpvoted } ?? false,
      isMine: true
    )
    if let existing {
      reviews[existing] = review
    } else {
      reviews.append(review)
    }
    reviewsByPlaceID[place.id] = reviews
  }

  public func deleteReview(for place: CampusPlace) {
    reviewsByPlaceID[place.id]?.removeAll(where: \.isMine)
  }
}
