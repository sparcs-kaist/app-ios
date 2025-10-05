//
//  FeedPostRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol FeedPostRepositoryProtocol: Sendable {
  func fetchPosts(cursor: String?, page: Int) async throws -> FeedPostPage
  func writePost(request: FeedCreatePost) async throws
  func deletePost(postID: String) async throws
  func vote(postID: String, type: FeedVoteType) async throws
  func deleteVote(postID: String) async throws
  func reportPost(postID: String, reason: FeedReportType, detail: String) async throws
}
