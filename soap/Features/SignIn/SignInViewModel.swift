//
//  SignInViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI
import Observation
import AuthenticationServices
import Factory

@Observable
class SignInViewModel {
  var isLoading: Bool = false
  var errorMessage: String? = nil

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol

  func signIn() {
    isLoading = true
    errorMessage = nil
    Task { @MainActor in
      do {
        try await authUseCase.signIn()
      } catch {
        errorMessage = error.localizedDescription
        logger.error("Sign in failed: \(error.localizedDescription)")
      }
      isLoading = false
    }
  }
}
