//
//  AraBoardRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol AraBoardRepositoryProtocol: Sendable {
  func fetchBoards() async throws -> [AraBoard]
  func fetchPosts(boardID: Int, page: Int, pageSize: Int) async throws -> AraPostPage
  func fetchPost(origin: AraBoardTarget.PostOrigin?, postID: Int) async throws -> AraPost
  func writePost(request: AraCreatePost) async throws
  func upvotePost(postID: Int) async throws
  func downvotePost(postID: Int) async throws
  func cancelVote(postID: Int) async throws
  func reportPost(postID: Int, type: AraContentReportType) async throws
}

actor AraBoardRepository: AraBoardRepositoryProtocol {
  private let provider: MoyaProvider<AraBoardTarget>

  // MARK: - Caches
  private var cachedBoards: [AraBoard]? = nil

  init(provider: MoyaProvider<AraBoardTarget>) {
    self.provider = provider
  }

  func fetchBoards() async throws -> [AraBoard] {
    if let cachedBoards {
      return cachedBoards
    }

    let response = try await provider.request(.fetchBoards)
    let boards: [AraBoard] = try response.map([AraBoardDTO].self).compactMap { $0.toModel() }

    self.cachedBoards = boards
    return boards
  }

  func fetchPosts(boardID: Int, page: Int, pageSize: Int) async throws -> AraPostPage {
    let response = try await provider.request(
      .fetchPosts(boardID: boardID, page: page, pageSize: pageSize)
    )
    let page: AraPostPage = try response.map(AraPostPageDTO.self).toModel()

    return page
  }

  func fetchPost(origin: AraBoardTarget.PostOrigin?, postID: Int) async throws -> AraPost {
    let response = try await provider.request(.fetchPost(origin: origin, postID: postID))
    let post: AraPost = try response.map(AraPostDTO.self).toModel()

    return post
  }

  func writePost(request: AraCreatePost) async throws {
    let response = try await provider.request(.writePost(AraPostRequestDTO.fromModel(request)))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func upvotePost(postID: Int) async throws {
    let response = try await provider.request(.upvote(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func downvotePost(postID: Int) async throws {
    let response = try await provider.request(.downvote(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func cancelVote(postID: Int) async throws {
    let response = try await provider.request(.cancelVote(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }

  func reportPost(postID: Int, type: AraContentReportType) async throws {
    let response = try await provider.request(.report(postID: postID, type: type))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
