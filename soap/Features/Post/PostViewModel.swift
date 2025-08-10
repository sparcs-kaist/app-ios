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
}

@Observable
class PostViewModel: PostViewModelProtocol {
  // MARK: - Properties
  var post: AraPost

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol

  // MARK: - Initialiser
  init(post: AraPost) {
    self.post = post
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
      if post.myVote == true {
        // cancel upvote
        post.myVote = nil
        post.upvotes -= 1
        try await araBoardRepository.cancelVote(postID: post.id)
      } else {
        // upvote
        if post.myVote == false {
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
      if post.myVote == false {
        // cancel downvote
        post.myVote = nil
        post.downvotes -= 1
        try await araBoardRepository.cancelVote(postID: post.id)
      } else {
        // downvote
        if post.myVote == true {
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
}
