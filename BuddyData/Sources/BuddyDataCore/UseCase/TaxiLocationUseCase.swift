//
//  TaxiLocationUseCase.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import Foundation
import BuddyDomain

public final class TaxiLocationUseCase: TaxiLocationUseCaseProtocol {
  private let taxiRoomRepository: TaxiRoomRepositoryProtocol
  public var locations: [TaxiLocation] = []
  
  public init(taxiRoomRepository: TaxiRoomRepositoryProtocol) {
    self.taxiRoomRepository = taxiRoomRepository
  }
  
  public func fetchLocations() async throws {
    self.locations = try await taxiRoomRepository.fetchLocations()
  }
  
  public func queryLocation(_ query: String) -> [TaxiLocation] {
    return locations.filter { $0.titleContains(query) }
  }
}
