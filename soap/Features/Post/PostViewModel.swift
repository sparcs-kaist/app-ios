//
//  PostViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import Observation
import Factory

@MainActor
protocol PostViewModelProtocol: Observable {
  var post: AraPost { get set }

  func fetchPost() async
  func upvote() async
  func downvote() async
  func writeComment(content: String) async
  func writeThreadedComment(commentID: Int, content: String) async
}

@Observable
class PostViewModel: PostViewModelProtocol {
  // MARK: - Properties
  var post: AraPost

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol
  @ObservationIgnored @Injected(
    \.araCommentRepository
  ) private var araCommentRepository: AraCommentRepositoryProtocol

  // MARK: - Initialiser
  init(post: AraPost) {
    self.post = post
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

  func writeComment(content: String) async {
    do {
      var comment: AraPostComment = try await araCommentRepository.writeComment(
        postID: post.id,
        content: content
      )
      comment.isMine = true

      self.post.comments.append(comment)
      self.post.commentCount += 1
    } catch {
      logger.error(error)
    }
  }

  func writeThreadedComment(commentID: Int, content: String) async {
    do {
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
    } catch {
      logger.error(error)
    }
  }
}
