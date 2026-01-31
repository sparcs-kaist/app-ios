//
//  TaxiLocationUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiLocationUseCaseProtocol: Actor {
  var locations: [TaxiLocation] { get }
  
  func fetchLocations() async throws
  func queryLocation(_ query: String) -> [TaxiLocation]
}
