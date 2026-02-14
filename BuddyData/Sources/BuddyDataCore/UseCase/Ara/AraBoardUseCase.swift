//
//  AraBoardUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import UIKit
import BuddyDomain

public final class AraBoardUseCase: AraBoardUseCaseProtocol {
  private let feature: String = "AraBoard"
  private let araBoardRepository: AraBoardRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  public init(
    araBoardRepository: AraBoardRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.araBoardRepository = araBoardRepository
    self.crashlyticsService = crashlyticsService
  }

  public func fetchBoards() async throws -> [AraBoard] {
    let context = CrashContext(
      feature: feature,
      metadata: [:]
    )
    return try await execute(context: context) {
      try await araBoardRepository.fetchBoards()
    }
  }

  public func fetchPosts(type: PostListType, page: Int, pageSize: Int, searchKeyword: String?) async throws -> AraPostPage {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "type": "\(type)",
        "page": "\(page)",
        "pageSize": "\(pageSize)",
        "searchKeyword": searchKeyword ?? "nil"
      ]
    )
    return try await execute(context: context) {
      try await araBoardRepository.fetchPosts(type: type, page: page, pageSize: pageSize, searchKeyword: searchKeyword)
    }
  }

  public func fetchPost(origin: PostOrigin?, postID: Int) async throws -> AraPost {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "origin": "\(String(describing: origin))",
        "postID": "\(postID)"
      ]
    )
    return try await execute(context: context) {
      try await araBoardRepository.fetchPost(origin: origin, postID: postID)
    }
  }

  public func fetchBookmarks(page: Int, pageSize: Int) async throws -> AraPostPage {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "page": "\(page)",
        "pageSize": "\(pageSize)"
      ]
    )
    return try await execute(context: context) {
      try await araBoardRepository.fetchBookmarks(page: page, pageSize: pageSize)
    }
  }

  public func uploadImage(image: UIImage) async throws -> AraAttachment {
    let context = CrashContext(
      feature: feature,
      metadata: [:]
    )
    return try await execute(context: context) {
      try await araBoardRepository.uploadImage(image: image)
    }
  }

  public func writePost(request: AraCreatePost) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "title": request.title,
        "hasContent": request.content.isEmpty ? "false" : "true"
      ]
    )
    try await execute(context: context) {
      try await araBoardRepository.writePost(request: request)
    }
  }

  public func upvotePost(postID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["postID": "\(postID)"]
    )
    try await execute(context: context) {
      try await araBoardRepository.upvotePost(postID: postID)
    }
  }

  public func downvotePost(postID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["postID": "\(postID)"]
    )
    try await execute(context: context) {
      try await araBoardRepository.downvotePost(postID: postID)
    }
  }

  public func cancelVote(postID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["postID": "\(postID)"]
    )
    try await execute(context: context) {
      try await araBoardRepository.cancelVote(postID: postID)
    }
  }

  public func reportPost(postID: Int, type: AraContentReportType) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: [
        "postID": "\(postID)",
        "type": "\(type)"
      ]
    )
    try await execute(context: context) {
      try await araBoardRepository.reportPost(postID: postID, type: type)
    }
  }

  public func deletePost(postID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["postID": "\(postID)"]
    )
    try await execute(context: context) {
      try await araBoardRepository.deletePost(postID: postID)
    }
  }

  public func addBookmark(postID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["postID": "\(postID)"]
    )
    try await execute(context: context) {
      try await araBoardRepository.addBookmark(postID: postID)
    }
  }

  public func removeBookmark(bookmarkID: Int) async throws {
    let context = CrashContext(
      feature: feature,
      metadata: ["bookmarkID": "\(bookmarkID)"]
    )
    try await execute(context: context) {
      try await araBoardRepository.removeBookmark(bookmarkID: bookmarkID)
    }
  }

  private func execute<T>(
    context: CrashContext,
    _ operation: () async throws -> T
  ) async throws -> T {
    do {
      return try await operation()
    } catch let networkError as NetworkError {
      crashlyticsService?.record(error: networkError, context: context)
      throw networkError
    } catch {
      let mappedError = AraBoardUseCaseError.unknown(underlying: error)
      crashlyticsService?.record(error: mappedError, context: context)
      throw mappedError
    }
  }
}
