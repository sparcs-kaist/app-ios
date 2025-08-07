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
}
