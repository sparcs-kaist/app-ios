//
//  TaxiChatRepositoryProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

protocol TaxiChatRepositoryProtocol: Sendable {
  func fetchChats(roomID: String) async throws
  func fetchChats(roomID: String, before: Date) async throws
  func fetchChats(roomID: String, after: Date) async throws
  func sendChat(_ chat: TaxiChatRequest) async throws
  func readChats(roomID: String) async throws
  func getPresignedURL(roomID: String) async throws -> TaxiChatPresignedURLDTO
  func uploadImage(presignedURL: TaxiChatPresignedURLDTO, imageData: Data) async throws
  func notifyImageUploadComplete(id: String) async throws
}
