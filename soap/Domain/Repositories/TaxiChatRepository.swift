//
//  TaxiChatRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Moya

enum TaxiChatErrorCode: Int {
  case fetchChatsFailed = 1001
  case sendChatFailed = 1002
  case readChatFailed = 1003
}

final class TaxiChatRepository: TaxiChatRepositoryProtocol, @unchecked Sendable {
  private let provider: MoyaProvider<TaxiChatTarget>

  init(provider: MoyaProvider<TaxiChatTarget>) {
    self.provider = provider
  }

  func fetchChats(roomID: String) async throws {
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

  func fetchChats(roomID: String, before: Date) async throws {
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

  func fetchChats(roomID: String, after: Date) async throws {
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

  func sendChat(_ chat: TaxiChatRequest) async throws {
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

  func readChats(roomID: String) async throws {
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

  func getPresignedURL(roomID: String) async throws -> TaxiChatPresignedURLDTO {
    do {
      let response = try await provider.request(.getPresignedURL(roomID: roomID))
      let result = try response.map(TaxiChatPresignedURLDTO.self)

      return result
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }

  func uploadImage(presignedURL: TaxiChatPresignedURLDTO, imageData: Data) async throws {
    let _ = try await provider
      .request(
        .uploadImage(url: presignedURL.url, fields: presignedURL.fields, imageData: imageData)
      )
  }

  func notifyImageUploadComplete(id: String) async throws {
    let _ = try await provider.request(.notifyImageUploadComplete(id: id))
  }
}
