//
//  TaxiRoomRepositoryProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

protocol TaxiRoomRepositoryProtocol {
  func fetchRooms() async throws -> [TaxiRoom]
  func fetchLocations() async throws -> [TaxiLocation]
  func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom
}
