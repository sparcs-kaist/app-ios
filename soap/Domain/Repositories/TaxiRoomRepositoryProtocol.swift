//
//  TaxiRoomRepositoryProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

protocol TaxiRoomRepositoryProtocol: Sendable {
  func fetchRooms() async throws -> [TaxiRoom]
  func fetchMyRooms() async throws -> (onGoing: [TaxiRoom], done: [TaxiRoom])
  func fetchLocations() async throws -> [TaxiLocation]
  func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom
  func joinRoom(id: String) async throws -> TaxiRoom
  func commitSettlement(id: String) async throws -> TaxiRoom
}
