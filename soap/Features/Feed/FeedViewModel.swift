//
//  FeedViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation
import Observation
import Factory

@MainActor
protocol FeedViewModelProtocol: Observable {
  func signOut() async throws
}

final class FeedViewModel: FeedViewModelProtocol {
  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol

  // MARK: - Functions
  func signOut() async throws {
    try await authUseCase.signOut()
  }

  func fetchInitialData() async throws {

  }
}
