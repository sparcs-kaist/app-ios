//
//  ContentViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import SwiftUI
import Combine
import Observation
import Factory

@Observable
@MainActor
class ContentViewModel {
  var isLoading = false
  var isAuthenticated = false
  private var cancellables = Set<AnyCancellable>()

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol

  init() {
    authUseCase.isAuthenticatedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newValue in
        guard let self = self else { return }
        self.isAuthenticated = newValue
      }
      .store(in: &cancellables)
  }

  func refreshAccessTokenIfNeeded() async {
    isLoading = true
    do {
      try await authUseCase.refreshAccessTokenIfNeeded()
    } catch {
      logger.error(error)
    }
    isLoading = false
  }
}
