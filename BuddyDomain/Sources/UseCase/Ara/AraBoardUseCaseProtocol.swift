//
//  AraBoardUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import UIKit

public protocol AraBoardUseCaseProtocol: Sendable {
  func fetchBoards() async throws -> [AraBoard]
  func fetchPosts(type: PostListType, page: Int, pageSize: Int, searchKeyword: String?) async throws -> AraPostPage
  func fetchPost(origin: PostOrigin?, postID: Int) async throws -> AraPost
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
