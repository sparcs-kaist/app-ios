//
//  SettingsView.swift
//  soap
//
//  Created by 하정우 on 7/23/25.
//

import Foundation
import SwiftUI
import BuddyDomain
import FirebaseAnalytics

public struct SettingsView: View {
  @Environment(\.openURL) private var openURL
  @State private var viewModel: SettingsViewModel
  @State private var showLogoutError: Bool = false
  @State private var isCrashlyticsEnabled: Bool = false
  @State private var showCreditView: Bool = false

  public init(_ viewModel: SettingsViewModel = .init()) {
    self.viewModel = viewModel
  }
  
  public var body: some View {
    NavigationStack {
      List {
        Section(header: Text(String(localized: "Miscellaneous", bundle: .module))) {
          appSettings
        }
        
        Section(header: Text(String(localized: "Services", bundle: .module))) {
          NavigationLink(String(localized: "Feed", bundle: .module)) { FeedSettingsView() }
          NavigationLink(String(localized: "Ara", bundle: .module)) { AraSettingsView() }
          NavigationLink(String(localized: "Taxi", bundle: .module)) { TaxiSettingsView() }
        }
        
        Section() {
          terms
        }
        
        if !Status.isProduction {
          Section(header: Text(String(localized: "Debug Menu", bundle: .module))) {
            Button(String(localized: "Force Crash", bundle: .module), systemImage: "exclamationmark.triangle") {
              fatalError("DEBUG: User forced a crash")
            }
            Button(String(localized: "Invoke Exception", bundle: .module), systemImage: "exclamationmark.triangle") {
              viewModel.handleException(NSError(domain: "Test", code: 1001))
            }
          }
        }

        Section {
          Button(String(localized: "Sign Out", bundle: .module), systemImage: "iphone.and.arrow.right.outward", role: .destructive) {
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
      .navigationTitle(Text(String(localized: "Settings", bundle: .module)))
      .alert(String(localized: "Error", bundle: .module), isPresented: $showLogoutError) {
        Button(role: .confirm) { }
      } message: {
        Text(String(localized: "An error occurred while signing out. Please try again later.", bundle: .module))
      }
      .navigationDestination(isPresented: $showCreditView) {
        CreditView()
      }
    }
    .analyticsScreen(name: "Settings", class: String(describing: Self.self))
  }
  
  private var appSettings: some View {
    Group {
//      NavigationLink("Notifications") { NotificationSettingsView() }

      Button(String(localized: "Change Language", bundle: .module), systemImage: "globe") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          openURL(url)
        }
      }

      Button(String(localized: "Send Feedback", bundle: .module), systemImage: "exclamationmark.bubble") {
        if let url = URL(string: "mailto:buddy@sparcs.org"), UIApplication.shared.canOpenURL(url) {
          openURL(url)
        }
      }
    }
  }
  
  private var terms: some View {
    Group {
      Button(String(localized: "Privacy Policy", bundle: .module), systemImage: "hand.raised.fill") {
        openURL(Constants.privacyPolicyURL)
      }
      Button(String(localized: "Terms of Use", bundle: .module), systemImage: "doc.text") {
        openURL(Constants.termsOfUseURL)
      }
      Button(String(localized: "Acknowledgements", bundle: .module), systemImage: "heart.text.square") {
        showCreditView = true
      }
    }
    .foregroundStyle(.primary)
  }
}

#Preview {
  SettingsView()
}
