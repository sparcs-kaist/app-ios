//
//  PostViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
protocol PostViewModelProtocol: Observable {
  var post: AraPost { get set }
  var isFoundationModelsAvailable: Bool { get }

  func fetchPost() async
  func upvote() async
  func downvote() async
  func writeComment(content: String) async throws -> AraPostComment
  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment
  func editComment(commentID: Int, content: String) async throws -> AraPostComment
  func report(type: AraContentReportType) async throws
  func summarisedContent() async -> String
  func deletePost() async throws
  func toggleBookmark() async
  func handleException(_ error: Error)
}

@Observable
class PostViewModel: PostViewModelProtocol {
  // MARK: - Properties
  var post: AraPost
  var isFoundationModelsAvailable: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol
  @ObservationIgnored @Injected(
    \.araCommentRepository
  ) private var araCommentRepository: AraCommentRepositoryProtocol
  @ObservationIgnored @Injected(
    \.foundationModelsUseCase
  ) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol

  // MARK: - Initialiser
  init(post: AraPost) {
    self.post = post
    Task {
      await refreshFoundationModelsAvailability()
    }
  }

  private func refreshFoundationModelsAvailability() async {
    isFoundationModelsAvailable = await foundationModelsUseCase.isAvailable()
  }

  private func insertThreadedComment(into comments: inout [AraPostComment], comment: AraPostComment) -> Bool {
    for idx in comments.indices {
      guard let parentComment = comment.parentComment else {
        return false
      }

      if comments[idx].id == parentComment {
        comments[idx].comments.append(comment)

        return true
      }
    }

    return false
  }

  // MARK: - Functions
  func fetchPost() async {
    do {
      let post: AraPost = try await araBoardRepository.fetchPost(origin: .board, postID: post.id)
      self.post = post
    } catch {
      logger.error(error)
    }
  }

  func upvote() async {
    let previousMyVote: Bool? = post.myVote
    let previousUpvotes: Int = post.upvotes

    do {
      if previousMyVote == true {
        // cancel upvote
        post.myVote = nil
        post.upvotes -= 1
        try await araBoardRepository.cancelVote(postID: post.id)
      } else {
        // upvote
        if previousMyVote == false {
          // remove downvote if there was
          post.downvotes -= 1
        }
        post.myVote = true
        post.upvotes += 1
        try await araBoardRepository.upvotePost(postID: post.id)
      }
    } catch {
      logger.error(error)
      post.upvotes = previousUpvotes
      post.myVote = previousMyVote
    }
  }

  func downvote() async {
    let previousMyVote: Bool? = post.myVote
    let previousDownvotes: Int = post.downvotes

    do {
      if previousMyVote == false {
        // cancel downvote
        post.myVote = nil
        post.downvotes -= 1
        try await araBoardRepository.cancelVote(postID: post.id)
      } else {
        // downvote
        if previousMyVote == true {
          // remove upvote if there was
          post.upvotes -= 1
        }
        post.myVote = false
        post.downvotes += 1
        try await araBoardRepository.downvotePost(postID: post.id)
      }
    } catch {
      logger.error(error)
      post.downvotes = previousDownvotes
      post.myVote = previousMyVote
    }
  }

  func writeComment(content: String) async throws -> AraPostComment {
    var comment: AraPostComment = try await araCommentRepository.writeComment(
      postID: post.id,
      content: content
    )
    comment.isMine = true

    self.post.comments.append(comment)
    self.post.commentCount += 1

    return comment
  }

  func writeThreadedComment(commentID: Int, content: String) async throws -> AraPostComment {
    var comment: AraPostComment = try await araCommentRepository.writeThreadedComment(
      commentID: commentID,
      content: content
    )
    comment.isMine = true

    // insert threaded comments

    var comments: [AraPostComment] = self.post.comments
    _ = insertThreadedComment(into: &comments, comment: comment)

    self.post.comments = comments
    self.post.commentCount += 1

    return comment
  }

  func editComment(commentID: Int, content: String) async throws -> AraPostComment {
    var comment: AraPostComment = try await araCommentRepository.editComment(
      commentID: commentID,
      content: content
    )
    comment.isMine = true

    for idx in post.comments.indices {
      if post.comments[idx].id == commentID {
        post.comments[idx].content = content
        return post.comments[idx]
      }
      // scan through threads
      for threadIdx in post.comments[idx].comments.indices {
        if post.comments[idx].comments[threadIdx].id == commentID {
          post.comments[idx].comments[threadIdx].content = content
          return post.comments[idx]
        }
      }
    }

    return comment
  }

  func report(type: AraContentReportType) async throws {
    try await araBoardRepository.reportPost(postID: post.id, type: type)
  }

  func summarisedContent() async -> String {
    return await foundationModelsUseCase.summarise(post.content ?? "", maxWords: 50, tone: "concise")
  }

  func deletePost() async throws {
    try await araBoardRepository.deletePost(postID: post.id)
  }
  
  func toggleBookmark() async {
    let previousBookmarkStatus: Bool = post.myScrap
    
    do {
      if previousBookmarkStatus {
        guard let scrapId = post.scrapId else { return }
        
        post.myScrap = false
        try await araBoardRepository.removeBookmark(bookmarkID: scrapId)
      } else {
        post.myScrap = true
        try await araBoardRepository.addBookmark(postID: post.id)
      }
    } catch {
      logger.error(error)
      post.myScrap = previousBookmarkStatus
    }
  }
  
  func handleException(_ error: any Error) {
    crashlyticsService.recordException(error: error)
  }
}
