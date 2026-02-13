//
//  TaxiRoomRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiRoomRepositoryProtocol: Sendable {
  func fetchRooms() async throws -> [TaxiRoom]
  func fetchMyRooms() async throws -> (onGoing: [TaxiRoom], done: [TaxiRoom])
  func fetchLocations() async throws -> [TaxiLocation]
  func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom
  func joinRoom(id: String) async throws -> TaxiRoom
  func leaveRoom(id: String) async throws -> TaxiRoom
  func getRoom(id: String) async throws -> TaxiRoom
  func getPublicRoom(id: String) async throws -> TaxiRoom
  func commitSettlement(id: String) async throws -> TaxiRoom
  func commitPayment(id: String) async throws -> TaxiRoom
}
