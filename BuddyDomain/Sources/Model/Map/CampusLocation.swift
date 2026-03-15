//
//  CampusLocation.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 15/03/2026.
//

import Foundation
import MapKit

public struct CampusLocation: Hashable {
  public let id = UUID()
  public let name: String
  public let latitude: Double
  public let longitude: Double
  public let category: LocationCategory

  public init(name: String, latitude: Double, longitude: Double, category: LocationCategory) {
    self.name = name
    self.latitude = latitude
    self.longitude = longitude
    self.category = category
  }

  public var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
