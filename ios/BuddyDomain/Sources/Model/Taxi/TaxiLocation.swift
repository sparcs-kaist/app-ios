//
//  TaxiLocation.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import MapKit

public struct TaxiLocation: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: LocalizedString
  public let priority: Double?
  public let latitude: Double
  public let longitude: Double

  public init(
    id: String,
    title: LocalizedString,
    priority: Double?,
    latitude: Double,
    longitude: Double
  ) {
    self.id = id
    self.title = title
    self.priority = priority
    self.latitude = latitude
    self.longitude = longitude
  }
}

public extension TaxiLocation {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  func titleContains(_ text: String) -> Bool {
    return title.contains(text)
  }
}
