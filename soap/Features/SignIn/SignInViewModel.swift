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
class SignInViewModel: NSObject, ASWebAuthenticationPresentationContextProviding {

  var isSigningIn = false
  var errorMessage: String?

  private var cancellables = Set<AnyCancellable>()

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    // Replace with your actual app window
    return ASPresentationAnchor()
  }

  func signIn() {
    guard let authURL = URL(string: "http://10.251.1.14:3000/api/auth/sparcssso?redirect=%2Fmypage&isSPARCSApp=true") else {
      self.errorMessage = "Invalid login URL."
      return
    }

    let callbackScheme = "sparcsapp"  // This must match your Info.plist CFBundleURLSchemes

    let session = ASWebAuthenticationSession(
      url: authURL,
      callbackURLScheme: callbackScheme
    ) { callbackURL, error in
      DispatchQueue.main.async {
        if let error = error {
          self.errorMessage = "Login failed: \(error.localizedDescription)"
          return
        }

        guard let callbackURL = callbackURL else {
          self.errorMessage = "No callback URL received."
          return
        }

        // Extract token or query from callbackURL as needed
        print("Callback URL:", callbackURL)
        // For example:
        // if let token = URLComponents(string: callbackURL.absoluteString)?
        //     .queryItems?.first(where: { $0.name == "token" })?.value {
        //     // use token
        // }
      }
    }

    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true
    session.start()
  }
}
