//
//  TaxiLocationStorage.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import Foundation
import BuddyDomain

public class TaxiLocationStorage: TaxiLocationStorageProtocol {
  public var taxiLocations: [TaxiLocation] = []

  public func setLocation(_ locations: [TaxiLocation]) {
    self.taxiLocations = locations
  }
  
  public func queryLocation(_ query: String) -> [TaxiLocation] {
    return taxiLocations.filter { $0.titleContains(query) }
  }
}
