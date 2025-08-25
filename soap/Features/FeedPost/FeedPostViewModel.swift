//
//  FeedPostViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 24/08/2025.
//

import SwiftUI
import Observation
import Factory

@MainActor
protocol FeedPostViewModelProtocol: Observable {
  var state: FeedPostViewModel.ViewState { get }
  var comments: [FeedComment] { get set }

  func fetchComments(postID: String) async
}

@Observable
class FeedPostViewModel: FeedPostViewModelProtocol {
  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }

  // MARK: - Properties
  var state: ViewState = .loading
  var comments: [FeedComment] = []

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.feedCommentRepository
  ) private var feedCommentRepository: FeedCommentRepositoryProtocol

  // MARK: - Functions
  func fetchComments(postID: String) async {
    do {
      let comments: [FeedComment] = try await feedCommentRepository.fetchComments(postID: postID)
      self.comments = comments
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }
}
