//
//  ActivePostViewModel.swift
//  BuddyFeature
//
//  Created by Jungwoo Ha on 19/10/2026.
//

import Foundation

/// Holds the view model of the one post shown in the detail or the panel, so
/// a draft survives when the layout moves the post between them.
@MainActor
final class ActivePostViewModel {
  // MARK: - Properties
  private var postID: String? = nil
  private var viewModel: FeedPostViewModelProtocol? = nil

  // MARK: - Functions
  func viewModel(for postID: String) -> FeedPostViewModelProtocol {
    if self.postID == postID, let viewModel { return viewModel }
    let viewModel = FeedPostViewModel()
    self.postID = postID
    self.viewModel = viewModel
    return viewModel
  }

  func reset() {
    postID = nil
    viewModel = nil
  }
}
