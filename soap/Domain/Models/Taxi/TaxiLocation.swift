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
  let title: LocalizedString
  let priority: Double?
  let latitude: Double
  let longitude: Double
}

extension TaxiLocation {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  func titleContains(_ text: String) -> Bool {
    return title.contains(text)
  }
}
