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
import BuddyDomain

@Observable
@MainActor
class ContentViewModel {
  var isLoading = true
  var isAuthenticated = false
  private var cancellables = Set<AnyCancellable>()

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol

  init() {
    authUseCase.isAuthenticatedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newValue in
        guard let self = self else { return }
        self.isAuthenticated = newValue
        isLoading = false
      }
      .store(in: &cancellables)
  }

  func refreshAccessTokenIfNeeded() async {
    isLoading = true
    do {
      // Avoid forcing refresh when token is still valid
      try await authUseCase.refreshAccessToken(force: false)
      await userUseCase.fetchUsers()
    } catch {
      logger.error(error)
    }
    isLoading = false
  }
  
  func fetchTaxiLocations() async {
    do {
      try await taxiLocationUseCase.fetchLocations()
    } catch {
      logger.error(error)
    }
  }
}
