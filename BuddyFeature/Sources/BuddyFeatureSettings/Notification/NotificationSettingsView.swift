//
//  NotificationSettingsView.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/6/26.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyPreviewSupport
import FirebaseAnalytics

struct NotificationSettingsView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.scenePhase) private var scenePhase
  @State private var viewModel: NotificationSettingsViewModelProtocol

  init(_ viewModel: NotificationSettingsViewModelProtocol = NotificationSettingsViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    List {
      if !viewModel.isAllowedBySystem {
        Section {
          blockedNotice
        }
      }

      Section {
        toggle(String(localized: "Comments on Your Posts", bundle: .module), for: .feedComment)
        toggle(String(localized: "Replies to Your Comments", bundle: .module), for: .feedReply)
      } header: {
        Text("Feed", bundle: .module)
      }

      Section {
        toggle(String(localized: "Chats", bundle: .module), for: .taxiChat)
        toggle(String(localized: "Ride Updates", bundle: .module), for: .taxiEvent)
      } header: {
        Text("Taxi", bundle: .module)
      } footer: {
        Text("Ride updates tell you when riders join or leave, about settlement and payment, and when your taxi is about to leave.", bundle: .module)
      }

      Section {
        toggle(String(localized: "Ara", bundle: .module), for: .ara)
        toggle(String(localized: "Timetable", bundle: .module), for: .timetable)
      } footer: {
        Text("These settings apply to this device only.", bundle: .module)
      }
    }
    .disabled(viewModel.state != .loaded)
    .overlay {
      switch viewModel.state {
      case .loading:
        ProgressView()
      case .loaded:
        EmptyView()
      case .error(let message):
        ContentUnavailableView {
          Label(String(localized: "Couldn’t Load Notifications", bundle: .module), systemImage: "bell.slash")
        } description: {
          Text(message)
        } actions: {
          Button(String(localized: "Try Again", bundle: .module)) {
            Task { await viewModel.load() }
          }
        }
        .background(Color(.systemGroupedBackground))
      }
    }
    .navigationTitle(String(localized: "Notifications", bundle: .module))
    .task {
      await viewModel.load()
    }
    // Notifications may have been allowed in Settings while Buddy was in the background.
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        Task { await viewModel.load() }
      }
    }
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button(role: .confirm) { }
      }, message: {
        Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
      }
    )
    .analyticsScreen(name: "Notification Settings", class: String(describing: Self.self))
  }

  /// Says why the switches below are off, with a button to where notifications can be turned on.
  /// In the style of Settings' own notices: an icon tile like its rows', a short explanation, and
  /// the way forward as a link.
  private var blockedNotice: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: "bell.slash.fill")
        .font(.body)
        .foregroundStyle(.white)
        .frame(width: 30, height: 30)
        .background(.red, in: .rect(cornerRadius: 7))
      VStack(alignment: .leading, spacing: 4) {
        Text("Notifications Are Off", bundle: .module)
          .font(.headline)
        Text("None of these arrive until you allow notifications for Buddy.", bundle: .module)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Button(String(localized: "Turn On in Settings", bundle: .module)) {
          if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
          }
        }
        .font(.subheadline)
        .buttonStyle(.borderless)
        .padding(.top, 4)
      }
    }
    .padding(.vertical, 6)
  }

  private func toggle(_ title: String, for category: NotificationCategory) -> some View {
    Toggle(title, isOn: Binding(
      get: { viewModel.preferences[category] ?? true },
      set: { enabled in
        Task { await viewModel.setNotifications(category, enabled: enabled) }
      }
    ))
    // None of these arrive while Settings turns notifications off for Buddy, which is changed
    // there, through the button above. A disabled toggle only fades its switch, so the label is
    // greyed too, as in Settings.
    .disabled(!viewModel.isAllowedBySystem)
    .foregroundStyle(viewModel.isAllowedBySystem ? .primary : .secondary)
  }
}

#Preview {
  NavigationStack {
    NotificationSettingsView(PreviewNotificationSettingsViewModel())
  }
}
