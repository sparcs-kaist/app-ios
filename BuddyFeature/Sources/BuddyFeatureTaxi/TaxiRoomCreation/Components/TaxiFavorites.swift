//
//  TaxiFavorites.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain

/// Your favourite places and routes, shared by every picker and route row on screen so starring
/// one in the room creation sheet shows at once in the Taxi tab beneath it.
@MainActor
@Observable
final class TaxiFavorites {
  static let shared = TaxiFavorites()

  private let store: TaxiFavoritesStore
  private(set) var placeIDs: [String]
  private(set) var routes: [TaxiFavoritesStore.Route]

  init(store: TaxiFavoritesStore = TaxiFavoritesStore()) {
    self.store = store
    self.placeIDs = store.placeIDs
    self.routes = store.routes
  }

  // MARK: Places

  func isFavorite(_ location: TaxiLocation) -> Bool {
    placeIDs.contains(location.id)
  }

  func toggleFavorite(_ location: TaxiLocation) {
    if let index = placeIDs.firstIndex(of: location.id) {
      placeIDs.remove(at: index)
    } else {
      placeIDs.append(location.id)
    }
    store.save(placeIDs: placeIDs)
  }

  // MARK: Routes

  func contains(source: TaxiLocation, destination: TaxiLocation) -> Bool {
    routes.contains(Self.route(source, destination))
  }

  /// Newest first, so the route just saved is the first one you see.
  func saveRoute(source: TaxiLocation, destination: TaxiLocation) {
    let route = Self.route(source, destination)
    guard !routes.contains(route) else { return }
    routes.insert(route, at: 0)
    store.save(routes: routes)
  }

  func removeRoute(_ route: TaxiFavoritesStore.Route) {
    routes.removeAll { $0 == route }
    store.save(routes: routes)
  }

  private static func route(_ source: TaxiLocation, _ destination: TaxiLocation) -> TaxiFavoritesStore.Route {
    TaxiFavoritesStore.Route(sourceID: source.id, destinationID: destination.id)
  }
}
