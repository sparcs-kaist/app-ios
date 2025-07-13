//
//  TaxiLocationShort.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import MapKit

struct TaxiLocationShort: Identifiable, Hashable {
  let id: String
  let title: LocalizedString
  let latitude: Double
  let longitude: Double
}

extension TaxiLocationShort {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
