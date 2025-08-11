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
  var post: AraPost { get }
  
  func fetchPost() async
  func upvote() async
  func downvote() async
  func upvoteComment(commentID: Int) async
  func downvoteComment(commentID: Int) async
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
  
  // Recursively find and mutate a comment by id inside a nested comment tree
  private func mutateComment(withID id: Int,
                             in comments: inout [AraPostComment],
                             _ body: (inout AraPostComment) -> Void) -> Bool {
    for i in comments.indices {
      if comments[i].id == id {
        body(&comments[i])
        return true
      }
      if var children = comments[i].comments {
        if mutateComment(withID: id, in: &children, body) {
          // write back mutated children
          comments[i].comments = children
          return true
        }
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
  
  func upvoteComment(commentID: Int) async {
    guard var comments = self.post.comments else { return }
    
    // Keep a snapshot so we can roll back on failure
    let backup = comments
    var previousMyVote: Bool? = nil
    
    let found = mutateComment(withID: commentID, in: &comments) { c in
      previousMyVote = c.myVote
      if c.myVote == true {
        // cancel upvote
        c.myVote = nil
        c.upvotes -= 1
      } else {
        // upvote
        if c.myVote == false {
          // remove downvote if there was
          c.downvotes -= 1
        }
        c.myVote = true
        c.upvotes += 1
      }
    }
    
    guard found else { return }
    self.post.comments = comments
    
    do {
      if previousMyVote == true {
        try await araCommentRepository.cancleVote(commentID: commentID)
      } else {
        try await araCommentRepository.upvoteComment(commentID: commentID)
      }
    } catch {
      logger.error(error)
      // roll back
      self.post.comments = backup
    }
  }
  
  func downvoteComment(commentID: Int) async {
    guard var comments = self.post.comments else { return }
    
    // Keep a snapshot so we can roll back on failure
    let backup = comments
    var previousMyVote: Bool? = nil
    
    let found = mutateComment(withID: commentID, in: &comments) { c in
      previousMyVote = c.myVote
      if c.myVote == false {
        // cancel downvote
        c.myVote = nil
        c.downvotes -= 1
      } else {
        // downvote
        if c.myVote == true {
          // remove upvote if there was
          c.upvotes -= 1
        }
        c.myVote = false
        c.downvotes += 1
      }
    }
    
    guard found else { return }
    self.post.comments = comments
    
    do {
      if previousMyVote == false {
        try await araCommentRepository.cancleVote(commentID: commentID)
      } else {
        try await araCommentRepository.downvoteComment(commentID: commentID)
      }
    } catch {
      logger.error(error)
      // roll back
      self.post.comments = backup
    }
  }
}
