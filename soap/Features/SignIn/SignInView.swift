//
//  SignInView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI
import BuddyDomain
import FirebaseAnalytics

struct SignInView: View {
  @State private var viewModel = SignInViewModel()

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  var body: some View {
    VStack {
      Spacer()
      buddyIcon
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
      Button(String(localized: "Okay"), role: .close) { }
    }, message: {
      Text(errorMessage)
    })
    .analyticsScreen(name: "Sign In", class: String(describing: Self.self))
  }

  /// The BuddyIcon artwork has an opaque backdrop baked in — there is no alpha channel.
  /// On iOS that backdrop is the same colour as the system background, so the mark looks
  /// like it floats. AppKit's window background is a shade lighter, which turns the same
  /// asset into a visible hard-edged square, so on macOS it is clipped to the standard
  /// icon squircle and given a drop shadow to read as a deliberate app icon instead.
  @ViewBuilder
  private var buddyIcon: some View {
    let image = Image(.buddyIcon)
      .resizable()
      .scaledToFit()
      .frame(width: 192, height: 192)

    #if os(macOS)
    image
      .clipShape(.rect(cornerRadius: 44, style: .continuous))
      .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    #else
    image
    #endif
  }
}


#Preview {
  SignInView()
}
