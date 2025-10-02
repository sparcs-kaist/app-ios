//
//  SignInView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI

struct SignInView: View {
  @State private var viewModel = SignInViewModel()

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  var body: some View {
    VStack {
      Spacer()
      Text("SPARCS APP INTERNAL")
        .fontWeight(.medium)
        .fontDesign(.monospaced)
        .font(.title2)
      Spacer()
      
      Text(try! AttributedString(markdown: "By continuing, you agree to our [Terms of Use](\(Constants.termsOfUseURL.absoluteString)) and [Privacy Policy](\(Constants.privacyPolicyURL.absoluteString)).")) // can be force unwrapped since it will not throw
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .font(.caption)
      
      Button(action: {
        Task {
          do {
            try await viewModel.signIn()
          } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
          }
        }
      }, label: {
        Group {
          if viewModel.isLoading {
            ProgressView()
              .tint(.white)
          } else {
            Text("Sign In with SPARCS SSO")
              .fontWeight(.medium)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
      })
      .buttonStyle(.glassProminent)
      .disabled(viewModel.isLoading)
    }
    .padding()
    .alert("Error", isPresented: $showErrorAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(errorMessage)
    })
  }
}


#Preview {
  SignInView()
}
