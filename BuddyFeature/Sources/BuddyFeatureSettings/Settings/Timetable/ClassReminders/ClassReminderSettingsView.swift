//
//  ClassReminderSettingsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import SwiftUI
import UIKit
import BuddyDomain
import FirebaseAnalytics

struct ClassReminderSettingsView: View {
  @State private var viewModel: ClassReminderSettingsViewModelProtocol
  @Environment(\.scenePhase) private var scenePhase

  init(_ viewModel: ClassReminderSettingsViewModelProtocol = ClassReminderSettingsViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    List {
      Section {
        Toggle(String(localized: "Class Reminders", bundle: .module), isOn: $viewModel.settings.isEnabled)
      } footer: {
        Text("Paused automatically during midterm and final exam weeks.", bundle: .module)
      }

      if viewModel.settings.isEnabled {
        Section {
          Picker(String(localized: "Remind Me With", bundle: .module), selection: $viewModel.settings.style) {
            Text("Live Activity", bundle: .module).tag(ClassReminderStyle.liveActivity)
            Text("Notification", bundle: .module).tag(ClassReminderStyle.notification)
          }
          .pickerStyle(.inline)
          .labelsHidden()
        } header: {
          Text("Remind Me With", bundle: .module)
        } footer: {
          styleFooter
        }

        Section {
          Picker(String(localized: "Lead Time", bundle: .module), selection: $viewModel.settings.leadMinutes) {
            ForEach(ClassReminderSettings.leadMinuteOptions, id: \.self) { minutes in
              Text("\(minutes) min before", bundle: .module).tag(minutes)
            }
          }
          Toggle(String(localized: "Include Custom Blocks", bundle: .module), isOn: $viewModel.settings.includeCustomBlocks)
          if viewModel.settings.style == .liveActivity {
            Toggle(String(localized: "Show Next Class", bundle: .module), isOn: $viewModel.settings.upNext)
          }
          Toggle(String(localized: "Play Sound", bundle: .module), isOn: $viewModel.settings.sound)
        } footer: {
          if viewModel.settings.style == .liveActivity {
            Text("Show Next Class shows where your next class is in the last 15 minutes of a class.", bundle: .module)
          }
        }
      }
    }
    .navigationTitle(String(localized: "Class Reminders", bundle: .module))
    .animation(.default, value: viewModel.settings)
    .task { await viewModel.refreshAvailability() }
    .onChange(of: scenePhase) { _, phase in
      // Coming back from iOS Settings may have changed a permission.
      if phase == .active {
        Task { await viewModel.refreshAvailability() }
      }
    }
    .analyticsScreen(name: "Class Reminder Settings", class: String(describing: Self.self))
  }

  @ViewBuilder
  private var styleFooter: some View {
    switch viewModel.availability {
    case .available:
      switch viewModel.settings.style {
      case .liveActivity:
        Text("Shows the next class and where it is on the Lock Screen and in the Dynamic Island.", bundle: .module)
      case .notification:
        Text("Sends a notification before each class.", bundle: .module)
      }
    case .liveActivitiesOff:
      VStack(alignment: .leading, spacing: 6) {
        Text("Live Activities are turned off for Buddy, so you'll get a notification instead.", bundle: .module)
        settingsButton
      }
    case .notificationsDenied:
      VStack(alignment: .leading, spacing: 6) {
        Text("Notifications are turned off for Buddy, so reminders can't be delivered.", bundle: .module)
        settingsButton
      }
    }
  }

  private var settingsButton: some View {
    Button(String(localized: "Open Settings", bundle: .module)) {
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    }
    .font(.footnote.weight(.semibold))
  }
}

#Preview {
  NavigationStack {
    ClassReminderSettingsView()
  }
}
