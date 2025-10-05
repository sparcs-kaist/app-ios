//
//  TaxiChatRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiChatRepositoryProtocol: Sendable {
  func fetchChats(roomID: String) async throws
  func fetchChats(roomID: String, before: Date) async throws
  func fetchChats(roomID: String, after: Date) async throws
  func sendChat(_ chat: TaxiChatRequest) async throws
  func readChats(roomID: String) async throws
  func getPresignedURL(roomID: String) async throws -> TaxiChatPresignedURL
  func uploadImage(presignedURL: TaxiChatPresignedURL, imageData: Data) async throws
  func notifyImageUploadComplete(id: String) async throws
}
