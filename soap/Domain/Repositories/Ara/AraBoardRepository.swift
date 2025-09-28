//
//  AraBoardRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import UIKit

@preconcurrency
import Moya

protocol AraBoardRepositoryProtocol: Sendable {
  func fetchBoards() async throws -> [AraBoard]
  func fetchPosts(type: AraBoardTarget.PostListType, page: Int, pageSize: Int, searchKeyword: String?) async throws -> AraPostPage
  func fetchPost(origin: AraBoardTarget.PostOrigin?, postID: Int) async throws -> AraPost
  func fetchBookmarks(page: Int, pageSize: Int) async throws -> AraPostPage
  func uploadImage(image: UIImage) async throws -> AraAttachment
  func writePost(request: AraCreatePost) async throws
  func upvotePost(postID: Int) async throws
  func downvotePost(postID: Int) async throws
  func cancelVote(postID: Int) async throws
  func reportPost(postID: Int, type: AraContentReportType) async throws
  func deletePost(postID: Int) async throws
  func addBookmark(postID: Int) async throws
  func removeBookmark(bookmarkID: Int) async throws
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

  func fetchPosts(type: AraBoardTarget.PostListType, page: Int, pageSize: Int, searchKeyword: String? = nil) async throws -> AraPostPage {
    let response = try await provider.request(
      .fetchPosts(type: type, page: page, pageSize: pageSize, searchKeyword: searchKeyword)
    )
    let page: AraPostPage = try response.map(AraPostPageDTO.self).toModel()

    return page
  }
  
  func fetchPost(origin: AraBoardTarget.PostOrigin?, postID: Int) async throws -> AraPost {
    let response = try await provider.request(.fetchPost(origin: origin, postID: postID))
    let post: AraPost = try response.map(AraPostDTO.self).toModel()

    return post
  }
  
  func fetchBookmarks(page: Int, pageSize: Int) async throws -> AraPostPage {
    let response = try await provider.request(.fetchBookmarks(page: page, pageSize: pageSize))
    let page: AraPostPage = try response.map(AraBookmarkDTO.self).toModel()
    
    return page
  }

  func uploadImage(image: UIImage) async throws -> AraAttachment {
    guard let imageData = image.compressForUpload(maxSizeMB: 1.0, maxDimension: 500) else {
      throw NSError(domain: "AraBoardRepository", code: 1)
    }

    let response = try await provider.request(.uploadImage(imageData: imageData))
    let attachment: AraAttachment = try response.map(AraAttachmentDTO.self).toModel()

    return attachment
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

  func deletePost(postID: Int) async throws {
    let response = try await provider.request(.delete(postID: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }
  
  func addBookmark(postID: Int) async throws {
    let response = try await provider.request(.addBookmark(postId: postID))
    _ = try response.filterSuccessfulStatusCodes()
  }
  
  func removeBookmark(bookmarkID: Int) async throws {
    let response = try await provider.request(.removeBookmark(scrapId: bookmarkID))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
