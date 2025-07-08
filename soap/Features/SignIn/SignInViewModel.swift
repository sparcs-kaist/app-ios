//
//  SignInViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI
import Observation
import AuthenticationServices
import Combine

@Observable
class SignInViewModel {
  var isAuthenticated: Bool = false
  var isLoading: Bool = false
  var errorMessage: String? = nil

  func signIn() {
    isLoading = true
    errorMessage = nil
  }
}
