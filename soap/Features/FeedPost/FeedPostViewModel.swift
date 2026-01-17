//
//  FeedPostViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 24/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
protocol FeedPostViewModelProtocol: Observable {
  var state: FeedPostViewModel.ViewState { get }
  var comments: [FeedComment] { get set }
  var text: String { get set }
  var image: UIImage? { get set }
  var isAnonymous: Bool { get set }

  func fetchComments(postID: String, initial: Bool) async
  func writeComment(postID: String) async throws -> FeedComment
  func writeReply(commentID: String) async throws -> FeedComment
}

@Observable
class FeedPostViewModel: FeedPostViewModelProtocol {
  enum ViewState: Comparable {
    case loading
    case loaded
    case error(message: String)
  }

  // MARK: - Properties
  var state: ViewState = .loading
  var comments: [FeedComment] = []

  var text: String = ""
  var image: UIImage? = nil
  var isAnonymous: Bool = true

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.feedCommentRepository
  ) private var feedCommentRepository: FeedCommentRepositoryProtocol

  // MARK: - Functions
  func fetchComments(postID: String, initial: Bool) async {
    guard state != .loading || initial else { return }
    do {
      let comments: [FeedComment] = try await feedCommentRepository.fetchComments(postID: postID)
      self.comments = comments
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }

  func writeComment(postID: String) async throws -> FeedComment {
    let request = FeedCreateComment(
      content: text,
      isAnonymous: isAnonymous,
      image: nil
    )
    let comment: FeedComment = try await feedCommentRepository.writeComment(postID: postID, request: request)

    self.comments.append(comment)

    return comment
  }

  private func insertReply(into comments: inout [FeedComment], comment: FeedComment) -> Bool {
    for idx in comments.indices {
      guard let parentCommentID = comment.parentCommentID else {
        return false
      }

      if comments[idx].id == parentCommentID {
        comments[idx].replies.append(comment)

        return true
      }
    }

    return false
  }

  func writeReply(commentID: String) async throws -> FeedComment {
    let request = FeedCreateComment(content: text, isAnonymous: isAnonymous, image: nil)
    let comment: FeedComment = try await feedCommentRepository.writeReply(commentID: commentID, request: request)

    var comments: [FeedComment] = self.comments
    _ = insertReply(into: &comments, comment: comment)
    self.comments = comments

    return comment
  }
}
