//
//  TaxiFavorites.swift
//  BuddyFeature
//

import SwiftUI
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiFavorites")

/// Your favourite places and routes, shared by every picker and route row on screen so starring
/// one in the room creation sheet shows at once in the Taxi tab beneath it.
///
/// Places are kept on this device. Routes are kept by the Taxi service with your account; they
/// change here straight away and are sent after, and if the service refuses a change they are
/// read back from it, so they never stay out of step with what it holds.
@MainActor
@Observable
final class TaxiFavorites {
  static let shared = TaxiFavorites()

  /// A route from one place to another. The two directions are separate routes.
  struct Route: Hashable {
    let sourceID: String
    let destinationID: String
  }

  private let store: TaxiFavoritesStore
  private(set) var placeIDs: [String]
  /// Newest first.
  private(set) var routes: [Route] = []

  /// The most routes the row shows, so it stays a short list of the trips you take most recently.
  static let maximumRoutes = 10

  /// The Taxi service's ID for each saved route, needed to remove it; a route just saved has none
  /// until the service replies.
  @ObservationIgnored private var routeIDs: [Route: String] = [:]
  /// The last change to the routes waiting to be sent. Changes go one after another, so a route
  /// removed straight after it was saved is removed only once the service has given it an ID.
  @ObservationIgnored private var routeUpdate: Task<Void, Never>?

  @ObservationIgnored @Injected(\.taxiUserRepository) private var taxiUserRepository: TaxiUserRepositoryProtocol?

  init(store: TaxiFavoritesStore = TaxiFavoritesStore()) {
    self.store = store
    self.placeIDs = store.placeIDs
  }

  /// Reads the favourites again, for when another account signed in since they were last read,
  /// or the routes were changed on another device.
  func reload() {
    placeIDs = store.placeIDs
    enqueueRouteUpdate { [self] in
      await fetchRoutes()
    }
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

  /// The routes the row shows: the newest, up to `maximumRoutes`.
  var shownRoutes: [Route] {
    Array(routes.prefix(Self.maximumRoutes))
  }

  func contains(source: TaxiLocation, destination: TaxiLocation) -> Bool {
    routes.contains(Self.route(source, destination))
  }

  /// Newest first, so the route just saved is the first one you see.
  func saveRoute(source: TaxiLocation, destination: TaxiLocation) {
    guard let taxiUserRepository else { return }
    let route = Self.route(source, destination)
    guard !routes.contains(route) else { return }
    routes.insert(route, at: 0)

    enqueueRouteUpdate { [self] in
      do {
        let saved = try await taxiUserRepository.createFavoriteRoute(
          sourceID: route.sourceID,
          destinationID: route.destinationID
        )
        routeIDs[route] = saved.id
      } catch {
        logger.error("Failed to save favourite route: \(error.localizedDescription, privacy: .public)")
        await fetchRoutes()
      }
    }
  }

  func removeRoute(_ route: Route) {
    guard let taxiUserRepository else { return }
    routes.removeAll { $0 == route }

    enqueueRouteUpdate { [self] in
      // Saving it failed, so the service never had it.
      guard let id = routeIDs[route] else { return }
      do {
        try await taxiUserRepository.deleteFavoriteRoute(id: id)
        routeIDs[route] = nil
      } catch {
        logger.error("Failed to remove favourite route: \(error.localizedDescription, privacy: .public)")
        await fetchRoutes()
      }
    }
  }

  /// Replaces the routes with those the Taxi service holds. Kept as they are if it can't be
  /// reached, unless you are no longer signed in, so no one else sees them.
  private func fetchRoutes() async {
    guard let taxiUserRepository else { return }
    do {
      let saved = try await taxiUserRepository.fetchFavoriteRoutes()
        .sorted { $0.createdAt > $1.createdAt }
      routes = saved.map { Route(sourceID: $0.sourceID, destinationID: $0.destinationID) }
      routeIDs = Dictionary(
        saved.map { (Route(sourceID: $0.sourceID, destinationID: $0.destinationID), $0.id) },
        uniquingKeysWith: { first, _ in first }
      )
    } catch NetworkError.unauthorized {
      routes = []
      routeIDs = [:]
    } catch {
      logger.error("Failed to fetch favourite routes: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func enqueueRouteUpdate(_ operation: @escaping @MainActor () async -> Void) {
    let previous = routeUpdate
    routeUpdate = Task {
      await previous?.value
      await operation()
    }
  }

  private static func route(_ source: TaxiLocation, _ destination: TaxiLocation) -> Route {
    Route(sourceID: source.id, destinationID: destination.id)
  }
}
