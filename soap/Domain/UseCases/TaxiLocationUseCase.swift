//
//  TaxiLocationUseCase.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import Foundation
import SwiftyBeaver
import BuddyDomain

final class TaxiLocationUseCase: TaxiLocationUseCaseProtocol {
  private let taxiRoomRepository: TaxiRoomRepositoryProtocol
  public var locations: [TaxiLocation] = []
  
  init(taxiRoomRepository: TaxiRoomRepositoryProtocol) {
    self.taxiRoomRepository = taxiRoomRepository
  }
  
  func fetchLocations() async throws {
    self.locations = try await taxiRoomRepository.fetchLocations()
  }
  
  func queryLocation(_ query: String) -> [TaxiLocation] {
    return locations.filter { $0.titleContains(query) }
  }
}
