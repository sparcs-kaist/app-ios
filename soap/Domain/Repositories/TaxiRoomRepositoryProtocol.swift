//
//  TaxiRepositoryProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

protocol TaxiRepositoryProtocol {
  func fetchRooms() async throws -> [TaxiRoom]
  func fetchLocations() async throws -> [TaxiLocation]
  func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom
  func joinRoom(id: String) async throws -> TaxiRoom
}
