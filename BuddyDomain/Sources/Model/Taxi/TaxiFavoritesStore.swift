import Foundation

/// The places you starred in the Taxi tab, kept on this device until you sign out: the Taxi
/// service keeps favourite routes, but has nowhere to keep places. Places are stored by their IDs,
/// so a place the service renames keeps its star, and one it removes simply drops out.
public struct TaxiFavoritesStore {
  private let defaults: UserDefaults
  private static let placesKey = "taxi.favoritePlaces"

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public var placeIDs: [String] {
    defaults.stringArray(forKey: Self.placesKey) ?? []
  }

  public func save(placeIDs: [String]) {
    defaults.set(placeIDs, forKey: Self.placesKey)
  }

  /// Forgets every favourite place, when the account signs out, so the next account on this
  /// device doesn't see where the last one travels.
  public func clear() {
    defaults.removeObject(forKey: Self.placesKey)
  }
}
