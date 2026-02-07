//
//  NotificationSettingsViewModel.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/6/26.
//

import SwiftUI
import Factory
import BuddyDomain

@MainActor
@Observable
public final class NotificationSettingsViewModel {
  @ObservationIgnored @Injected(\.fcmUseCase) private var fcmUseCase: FCMUseCaseProtocol?
  
  var alertState: AlertState?
  var isAlertPresented: Bool = false
  
  var toggleState: [FeatureType: Bool] = [:]
  
  init() {
    for type in FeatureType.allCases {
      if let data = UserDefaults.standard.data(forKey: "fcm.\(type.rawValue)"),
         let status = try? JSONDecoder().decode(Bool.self, from: data) {
        updateToggleState(for: type, isActive: status)
      } else {
        // failed to fetch toggle status; defaulting to true
        updateToggleState(for: type, isActive: true)
      }
    }
  }
  
  func binding(for service: FeatureType) -> Binding<Bool> {
    Binding<Bool>(
      get: {
        self.toggleState[service, default: true]
      }, set: { isActive in
        Task {
          await self.toggle(for: service, isActive: isActive)
        }
      }
    )
  }
  
  private func toggle(for service: FeatureType, isActive: Bool) async {
    do {
      try await fcmUseCase?.manage(service: service, isActive: isActive)
      updateToggleState(for: service, isActive: isActive)
    } catch {
      alertState = .init(
        title: String(localized: "Failed to update toggle status"),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }
  
  private func updateToggleState(for service: FeatureType, isActive: Bool) {
    if let encoded = try? JSONEncoder().encode(isActive) {
      UserDefaults.standard.set(encoded, forKey: "fcm.\(service.rawValue)")
      toggleState[service] = isActive
    } else {
      alertState = .init(
        title: String(localized: "Failed to save toggle status"),
        message: String(localized: "Failed to encode toggle status")
      )
      isAlertPresented = true
    }
  }
}
