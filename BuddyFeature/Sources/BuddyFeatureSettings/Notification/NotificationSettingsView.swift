//
//  NotificationSettingsView.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/6/26.
//

import SwiftUI
import BuddyDomain

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
      viewModel.alertState?.title ?? "Error",
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? "Unexpected Error")
      }
    )
    .navigationTitle("Notifications")
  }
}

#Preview {
  NotificationSettingsView()
}
