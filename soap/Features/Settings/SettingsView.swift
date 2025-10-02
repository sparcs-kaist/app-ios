//
//  SettingsView.swift
//  soap
//
//  Created by 하정우 on 7/23/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.openURL) private var openURL
  @State private var viewModel: SettingsViewModel
  @State private var showLogoutError: Bool = false
  
  init(_ viewModel: SettingsViewModel = .init()) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Miscellaneous")) {
          appSettings
        }
        
        Section(header: Text("Services")) {
          NavigationLink("Ara") { AraSettingsView() }
          NavigationLink("Taxi") { TaxiSettingsView() }
        }
        
        Section() {
          terms
          Button("Sign Out", systemImage: "iphone.and.arrow.right.outward", role: .destructive) {
            Task {
              do {
                try await viewModel.signOut()
              } catch {
                showLogoutError = true
              }
            }
          }
          .foregroundStyle(.red)
        }
      }
      .navigationTitle(Text("Settings"))
      .alert("Error", isPresented: $showLogoutError) {
        Button(role: .confirm) { }
      } message: {
        Text("An error occurred while signing out. Please try again later.")
      }
    }
  }
  
  private var appSettings: some View {
    Group {
      Button("Change Language", systemImage: "globe") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          openURL(url)
        }
      }
      Button("Send Feedback", systemImage: "exclamationmark.bubble") {
        if let url = URL(string: "mailto:app@sparcs.org"), UIApplication.shared.canOpenURL(url) {
          openURL(url)
        }
      }
    }
  }
  
  private var terms: some View {
    Group {
      Button("Privacy Policy", systemImage: "list.bullet.clipboard") {
        openURL(Constants.privacyPolicyURL)
      }
      Button("Terms of Use", systemImage: "list.bullet.clipboard") {
        openURL(Constants.termsOfUseURL)
      }
    }
    .foregroundStyle(.primary)
  }
}

#Preview {
  SettingsView()
}
