//
//  TaxiLocationStorage.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import Foundation


protocol TaxiLocationStorageProtocol {
  var taxiLocations: [TaxiLocation] { get set }
  func setLocation(_ locations: [TaxiLocation])
  func queryLocation(_ query: String) -> [TaxiLocation]
}

class TaxiLocationStorage: TaxiLocationStorageProtocol {
  var taxiLocations: [TaxiLocation] = []
  
  func setLocation(_ locations: [TaxiLocation]) {
    self.taxiLocations = locations
  }
  
  func queryLocation(_ query: String) -> [TaxiLocation] {
    return taxiLocations.filter { $0.titleContains(query) }
  }
}
