//
//  SettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import Foundation
import Factory
import BuddyDomain

@MainActor
@Observable
public class SettingsViewModel {
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?

  public init() { }

  public func signOut() async throws {
    guard let authUseCase else { return }

    try await authUseCase.signOut()
  }
  
  public func handleException(_ error: Error) {
    crashlyticsService?.recordException(error: error)
  }
}
