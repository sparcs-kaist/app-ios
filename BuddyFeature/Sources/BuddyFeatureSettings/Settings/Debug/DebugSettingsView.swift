//
//  DebugSettingsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/10/2026.
//

#if DEBUG
import SwiftUI
import BuddyFeatureShared

/// Settings for development, compiled into Debug builds only, whichever server they use.
struct DebugSettingsView: View {
  let viewModel: SettingsViewModel
  @State private var showsTipsResetAlert = false
  @State private var showsTipsImmediately = BuddyTips.showsTipsImmediately

  var body: some View {
    List {
      Section {
        Button(String(localized: "Force Crash", bundle: .module), systemImage: "exclamationmark.triangle") {
          fatalError("DEBUG: User forced a crash")
        }
        Button(String(localized: "Invoke Exception", bundle: .module), systemImage: "exclamationmark.triangle") {
          viewModel.handleException(NSError(domain: "Test", code: 1001))
        }
      } header: {
        Text("Crashlytics", bundle: .module)
      }

      Section {
        Button(String(localized: "Reset Tips", bundle: .module), systemImage: "lightbulb.max") {
          BuddyTips.requestReset()
          showsTipsResetAlert = true
        }
        Toggle(isOn: $showsTipsImmediately) {
          Label(String(localized: "Show Tips Immediately", bundle: .module), systemImage: "bolt")
        }
        .onChange(of: showsTipsImmediately) { _, newValue in
          BuddyTips.showsTipsImmediately = newValue
        }
      } header: {
        Text("Tips", bundle: .module)
      } footer: {
        Text("Reset Tips shows every tip again and starts the timetable onboarding over, as for a new user. Both settings apply the next time Buddy opens.", bundle: .module)
      }
    }
    .navigationTitle(Text("Debug Settings", bundle: .module))
    .alert(String(localized: "Tips Reset", bundle: .module), isPresented: $showsTipsResetAlert) {
      Button(String(localized: "Quit Buddy", bundle: .module), role: .destructive) {
        exit(0)
      }
      Button(String(localized: "Later", bundle: .module), role: .cancel) { }
    } message: {
      Text("Tips show again the next time Buddy opens.", bundle: .module)
    }
  }
}
#endif
