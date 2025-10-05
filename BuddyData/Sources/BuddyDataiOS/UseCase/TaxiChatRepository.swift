//
//  TaxiChatRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Moya
import BuddyDomain
import BuddyDataCore
import BuddyDataRealtime

public enum TaxiChatErrorCode: Int {
  case fetchChatsFailed = 1001
  case sendChatFailed = 1002
  case readChatFailed = 1003
}

public final class TaxiChatRepository: TaxiChatRepositoryProtocol, @unchecked Sendable {
  private let provider: MoyaProvider<TaxiChatTarget>

  public init(provider: MoyaProvider<TaxiChatTarget>) {
    self.provider = provider
  }

  public func fetchChats(roomID: String) async throws {
    let response = try await provider.request(.fetchChats(roomID: roomID))
    let result = try response.map(TaxiChatResponseDTO.self)

    if result.result == false {
      throw NSError(
        domain: "TaxiChatRepository",
        code: TaxiChatErrorCode.fetchChatsFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "Failed to fetch chats"]
      )
    }
  }

  public func fetchChats(roomID: String, before: Date) async throws {
    let response = try await provider.request(
      .fetchChatsBefore(roomID: roomID, date: before.toISO8601)
    )
    let result = try response.map(TaxiChatResponseDTO.self)

    if result.result == false {
      throw NSError(
        domain: "TaxiChatRepository",
        code: TaxiChatErrorCode.fetchChatsFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "Failed to fetch chats"]
      )
    }
  }

  public func fetchChats(roomID: String, after: Date) async throws {
    let response = try await provider.request(
      .fetchChatsAfter(roomID: roomID, date: after.toISO8601)
    )
    let result = try response.map(TaxiChatResponseDTO.self)

    if result.result == false {
      throw NSError(
        domain: "TaxiChatRepository",
        code: TaxiChatErrorCode.fetchChatsFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "Failed to fetch chats"]
      )
    }
  }

  public func sendChat(_ chat: TaxiChatRequest) async throws {
    let response = try await provider.request(
      .sendChat(request: TaxiChatRequestDTO.fromModel(chat))
    )
    let result = try response.map(TaxiChatResponseDTO.self)

    if result.result == false {
      throw NSError(
        domain: "TaxiChatRepository",
        code: TaxiChatErrorCode.sendChatFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "Failed to send chat"]
      )
    }
  }

  public func readChats(roomID: String) async throws {
    let response = try await provider.request(.readChat(roomID: roomID))
    let result = try response.map(TaxiChatResponseDTO.self)

    if result.result == false {
      throw NSError(
        domain: "TaxiChatRepository",
        code: TaxiChatErrorCode.readChatFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey: "Failed to read chats"]
      )
    }
  }

  public func getPresignedURL(roomID: String) async throws -> TaxiChatPresignedURL {
    do {
      let response = try await provider.request(.getPresignedURL(roomID: roomID))
      let result = try response.map(TaxiChatPresignedURLDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }

  public func uploadImage(presignedURL: TaxiChatPresignedURL, imageData: Data) async throws {
    let _ = try await provider
      .request(
        .uploadImage(url: presignedURL.url, fields: presignedURL.fields, imageData: imageData)
      )
  }

  public func notifyImageUploadComplete(id: String) async throws {
    let _ = try await provider.request(.notifyImageUploadComplete(id: id))
  }
}
