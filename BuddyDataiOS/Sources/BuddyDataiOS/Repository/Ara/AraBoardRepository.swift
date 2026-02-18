//
//  AraBoardRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import UIKit
import BuddyDomain
import BuddyDataCore

@preconcurrency
import Moya

public actor AraBoardRepository: AraBoardRepositoryProtocol {
  private let provider: MoyaProvider<AraBoardTarget>

  // MARK: - Caches
  private var cachedBoards: [AraBoard]? = nil

  public init(provider: MoyaProvider<AraBoardTarget>) {
    self.provider = provider
  }

  public func fetchBoards() async throws -> [AraBoard] {
    if let cachedBoards {
      return cachedBoards
    }

    let response = try await provider.request(.fetchBoards)
    let boards: [AraBoard] = try response.map([AraBoardDTO].self).compactMap { $0.toModel() }

    self.cachedBoards = boards
    return boards
  }

  public func fetchPosts(type: PostListType, page: Int, pageSize: Int, searchKeyword: String? = nil) async throws -> AraPostPage {
    let response = try await provider.request(
      .fetchPosts(type: type, page: page, pageSize: pageSize, searchKeyword: searchKeyword)
    )
    let page: AraPostPage = try response.map(AraPostPageDTO.self).toModel()

    return page
  }
  
  public func fetchPost(origin: PostOrigin?, postID: Int) async throws -> AraPost {
    let response = try await provider.request(.fetchPost(origin: origin, postID: postID))
    let post: AraPost = try response.map(AraPostDTO.self).toModel()

    return post
  }
  
  public func fetchBookmarks(page: Int, pageSize: Int) async throws -> AraPostPage {
    let response = try await provider.request(.fetchBookmarks(page: page, pageSize: pageSize))
    let page: AraPostPage = try response.map(AraBookmarkDTO.self).toModel()
    
    return page
  }

  public func uploadImage(image: UIImage) async throws -> AraAttachment {
    guard let imageData = image.compressForUpload(maxSizeMB: 1.0, maxDimension: 500) else {
      throw NSError(domain: "AraBoardRepository", code: 1)
    }

    let response = try await provider.request(.uploadImage(imageData: imageData))
    let attachment: AraAttachment = try response.map(AraAttachmentDTO.self).toModel()

    return attachment
  }

  public func writePost(request: AraCreatePost) async throws {
    _ = try await provider.request(.writePost(AraPostRequestDTO.fromModel(request)))
  }

  public func upvotePost(postID: Int) async throws {
    _ = try await provider.request(.upvote(postID: postID))
  }

  public func downvotePost(postID: Int) async throws {
    _ = try await provider.request(.downvote(postID: postID))
  }

  public func cancelVote(postID: Int) async throws {
    _ = try await provider.request(.cancelVote(postID: postID))
  }

  public func reportPost(postID: Int, type: AraContentReportType) async throws {
    _ = try await provider.request(.report(postID: postID, type: type))
  }

  public func deletePost(postID: Int) async throws {
    _ = try await provider.request(.delete(postID: postID))
  }
  
  public func addBookmark(postID: Int) async throws {
    _ = try await provider.request(.addBookmark(postId: postID))
  }
  
  public func removeBookmark(bookmarkID: Int) async throws {
    _ = try await provider.request(.removeBookmark(scrapId: bookmarkID))
  }
}
