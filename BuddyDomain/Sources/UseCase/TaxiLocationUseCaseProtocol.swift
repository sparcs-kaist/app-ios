//
//  TaxiLocationUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

@MainActor
public protocol TaxiLocationUseCaseProtocol: Sendable {
  var locations: [TaxiLocation] { get }
  
  func fetchLocations() async throws
  func queryLocation(_ query: String) -> [TaxiLocation]
}
