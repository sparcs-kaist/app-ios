//
//  TaxiLocationStorageProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiLocationStorageProtocol {
  var taxiLocations: [TaxiLocation] { get set }
  func setLocation(_ locations: [TaxiLocation])
  func queryLocation(_ query: String) -> [TaxiLocation]
}
