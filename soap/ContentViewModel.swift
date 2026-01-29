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
import Version

@Observable
@MainActor
class ContentViewModel {
  var isLoading = true
  var isAuthenticated = false
  var isUpdateRequired = false
  private var cancellables = Set<AnyCancellable>()
  private var lastCheckTime: Date?

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol?
  @ObservationIgnored @Injected(\.versionRepository) private var versionRepository: VersionRepositoryProtocol?

  init() {
    guard let authUseCase else { return }

    authUseCase.isAuthenticatedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newValue in
        guard let self = self else { return }
        self.isAuthenticated = newValue
        isLoading = false
      }
      .store(in: &cancellables)
  }
  
  func onActivation() async {
    isLoading = true
    
    await checkUpdateIfNeeded()
    if isUpdateRequired { return }
    await refreshAccessTokenIfNeeded()
    
    isLoading = false
  }

  func refreshAccessTokenIfNeeded() async {
    guard let authUseCase, let userUseCase else { return }

    do {
      // Avoid forcing refresh when token is still valid
      try await authUseCase.refreshAccessToken(force: false)
      await userUseCase.fetchUsers()
    } catch {
      logger.error(error)
    }
  }
  
  func fetchTaxiLocations() async {
    guard let taxiLocationUseCase else { return }
    
    do {
      try await taxiLocationUseCase.fetchLocations()
    } catch {
      logger.error(error)
    }
  }
  
  func checkUpdateIfNeeded() async {
    let now = Date()
    
    if lastCheckTime == nil || now.timeIntervalSince(lastCheckTime!) > 3600 { // 1 hour interval
      await checkForUpdates()
      lastCheckTime = now
    }
  }
  
  func resetTimer() {
    lastCheckTime = nil
  }
  
  private func checkForUpdates() async  {
    guard let versionRepository else { return }

    logger.debug("Checking for updates")
    guard let requiredVersion = try? await versionRepository.getMinimumVersion() else {
      logger.error("Failed to fetch minimum required version.")
      isUpdateRequired = false // TODO: check if network connection is lost
      return
    }
    
    let currentVersion = Bundle.main.version
    
    isUpdateRequired = currentVersion < requiredVersion
    logger.debug("currentVersion: \(currentVersion), requiredVersion: \(requiredVersion), isUpdateRequired: \(isUpdateRequired)")
  }
}
