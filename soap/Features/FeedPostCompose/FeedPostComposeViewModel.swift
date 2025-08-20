//
//  FeedPostComposeViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import Foundation
import Observation
import Factory

@MainActor
protocol FeedPostComposeViewModelProtocol: Observable {
  var feedUser: FeedUser? { get }
  var text: String { get  set }
  var selectedComposeType: FeedPostComposeViewModel.ComposeType { get set }

  func fetchFeedUser() async
}

@Observable
class FeedPostComposeViewModel: FeedPostComposeViewModelProtocol {
  enum ComposeType: Int, Hashable {
    case publicly = 0
    case anonymously = 1
  }

  // MARK: - Properties
  var feedUser: FeedUser?
  var text: String = ""
  var selectedComposeType: ComposeType = .anonymously

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol

  // MARK: - Functions
  func fetchFeedUser() async {
    self.feedUser = await userUseCase.feedUser
  }
}
