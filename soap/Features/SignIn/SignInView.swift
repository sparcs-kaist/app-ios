//
//  SignInView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI
import BuddyDomain

struct SignInView: View {
  @State private var viewModel = SignInViewModel()

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  var body: some View {
    VStack {
      Spacer()
      Image(.buddyIcon)
        .resizable()
        .scaledToFit()
        .frame(width: 192, height: 192)
      Spacer()

      HStack {
        Text("Sponsored by")
          .font(.callout)
          .fontWeight(.medium)

        Image(.hyundaiMobisInline)
          .resizable()
          .scaledToFit()
          .frame(height: 24)
      }

      Spacer()
        .frame(height: 16)

      Group {
        if let attributed = try? AttributedString(markdown: String(localized: "By continuing, you agree to our [Terms of Use](\(Constants.termsOfUseURL.absoluteString)) and [Privacy Policy](\(Constants.privacyPolicyURL.absoluteString)).")) {
          Text(attributed)
        } else {
          Text("By continuing, you agree to our Terms of Use and Privacy Policy.")
        }
      }
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
            Text("Continue with SPARCS SSO")
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
