import Foundation

/// The places and routes you starred in the Taxi tab, kept on this device until you sign out: the
/// Taxi service has nowhere to keep them. Places are stored by their IDs, so a place the service renames keeps its
/// star, and one it removes simply drops out.
public struct TaxiFavoritesStore {
  /// A route from one place to another. The two directions are separate routes.
  public struct Route: Codable, Hashable, Sendable {
    public let sourceID: String
    public let destinationID: String

    public init(sourceID: String, destinationID: String) {
      self.sourceID = sourceID
      self.destinationID = destinationID
    }
  }

  private let defaults: UserDefaults
  private static let placesKey = "taxi.favoritePlaces"
  private static let routesKey = "taxi.favoriteRoutes"

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public var placeIDs: [String] {
    defaults.stringArray(forKey: Self.placesKey) ?? []
  }

  public var routes: [Route] {
    guard let data = defaults.data(forKey: Self.routesKey) else { return [] }
    return (try? JSONDecoder().decode([Route].self, from: data)) ?? []
  }

  public func save(placeIDs: [String]) {
    defaults.set(placeIDs, forKey: Self.placesKey)
  }

  public func save(routes: [Route]) {
    guard let data = try? JSONEncoder().encode(routes) else { return }
    defaults.set(data, forKey: Self.routesKey)
  }

  /// Forgets every favourite, when the account signs out, so the next account on this device
  /// doesn't see where the last one travels.
  public func clear() {
    defaults.removeObject(forKey: Self.placesKey)
    defaults.removeObject(forKey: Self.routesKey)
  }
}
