//
//  NotificationSettingsView.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/6/26.
//

import Foundation
import SwiftUI
import BuddyDomain
import FirebaseAnalytics

struct NotificationSettingsView: View {
  @State private var viewModel = NotificationSettingsViewModel()
  @State private var toggleState = [FeatureType: Bool]()
  var body: some View {
    List {
      ForEach(FeatureType.allCases, id: \.self) { type in
        Toggle(isOn: viewModel.binding(for: type), label: {
          Text(type.prettyString)
        })
      }
    }
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
      }
    )
    .navigationTitle(String(localized: "Notifications", bundle: .module))
    .analyticsScreen(name: "Notification Settings", class: String(describing: Self.self))
  }
}

#Preview {
  NotificationSettingsView()
}
