//
//  MacSettingsView.swift
//  BuddyFeature
//

#if os(macOS)
import SwiftUI
import BuddyDomain
import FirebaseAnalytics
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "MacSettingsView")

/// Settings as a Mac app expects them: one window off the app menu (⌘,) with a pane
/// per service, instead of the sheet `FeedView`'s toolbar puts up on iOS.
///
/// This lives inside `BuddyFeatureSettings` rather than in the app target so that the
/// per-service screens it composes can stay internal to the module. Only this view is
/// public; `soapApp` just hands it to a `Settings` scene.
public struct MacSettingsView: View {
  public init() { }

  public var body: some View {
    TabView {
      Tab(String(localized: "General", bundle: .module), systemImage: "gear") {
        NavigationStack { GeneralSettingsPane() }
      }
      Tab(String(localized: "Feed", bundle: .module), systemImage: "text.rectangle.page") {
        NavigationStack { FeedSettingsView() }
      }
      Tab(String(localized: "Ara", bundle: .module), systemImage: "tray.full") {
        NavigationStack { AraSettingsView() }
      }
      Tab(String(localized: "Taxi", bundle: .module), systemImage: "car") {
        NavigationStack { TaxiSettingsView() }
      }
      Tab(String(localized: "Acknowledgements", bundle: .module), systemImage: "heart.text.square") {
        NavigationStack { CreditView() }
      }
    }
    // The per-service panes carry lists that collapse to nothing at the default
    // settings-window size.
    .frame(minWidth: 560, minHeight: 440)
    .analyticsScreen(name: "Settings", class: String(describing: Self.self))
  }
}

/// Everything from the iOS settings screen that is not one of the per-service
/// screens: app-level preferences, the legal links and signing out.
private struct GeneralSettingsPane: View {
  @Environment(\.openURL) private var openURL
  @State private var viewModel = SettingsViewModel()
  @State private var showLogoutError: Bool = false

  var body: some View {
    List {
      Section(header: Text("Miscellaneous", bundle: .module)) {
        Button(String(localized: "Change Language", bundle: .module), systemImage: "globe") {
          // The Language & Region pane; macOS has no per-app settings page.
          if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension") {
            openURL(url)
          }
        }

        Button(String(localized: "Send Feedback", bundle: .module), systemImage: "exclamationmark.bubble") {
          if let url = URL(string: "mailto:buddy@sparcs.org") {
            openURL(url)
          }
        }
      }

      Section {
        Button(String(localized: "Privacy Policy", bundle: .module), systemImage: "hand.raised.fill") {
          openURL(Constants.privacyPolicyURL)
        }
        Button(String(localized: "Terms of Use", bundle: .module), systemImage: "doc.text") {
          openURL(Constants.termsOfUseURL)
        }
      }
      .foregroundStyle(.primary)

      if !Status.isProduction {
        Section(header: Text("Debug Menu", bundle: .module)) {
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
              logger.error("Failed to sign out: \(error.localizedDescription, privacy: .public)")
              showLogoutError = true
            }
          }
        }
        .foregroundStyle(.red)
      }
    }
    .navigationTitle(Text("Settings", bundle: .module))
    .alert(String(localized: "Error", bundle: .module), isPresented: $showLogoutError) {
      Button(role: .confirm) { }
    } message: {
      Text("An error occurred while signing out. Please try again later.", bundle: .module)
    }
  }
}

#Preview {
  MacSettingsView()
}
#endif
