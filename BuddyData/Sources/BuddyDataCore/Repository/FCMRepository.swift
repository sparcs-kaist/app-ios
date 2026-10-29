//
//  FCMRepository.swift
//  BuddyData
//
//  Created by 하정우 on 2/4/26.
//

import Foundation
import BuddyDomain
import Moya

public final class FCMRepository: FCMRepositoryProtocol, @unchecked Sendable {
  private let provider: MoyaProvider<FCMTarget>
  
  public init(provider: MoyaProvider<FCMTarget>) {
    self.provider = provider
  }
  
  public func register(deviceUUID: String, fcmToken: String, deviceName: String, language: String) async throws {
    let _ = try await provider.request(.register(deviceUUID: deviceUUID, fcmToken: fcmToken, deviceName: deviceName, language: language))
  }
  
  public func unregister(deviceUUID: String) async throws {
    let _ = try await provider.request(.unregister(deviceUUID: deviceUUID))
  }

  public func fetchNotificationPreferences(deviceUUID: String) async throws -> [NotificationCategory: Bool] {
    let response = try await provider.request(.notificationPreferences(deviceUUID: deviceUUID))
    return try response.map(NotificationPreferencesDTO.self).toModel()
  }

  public func setNotificationPreference(_ category: NotificationCategory, isEnabled: Bool, deviceUUID: String) async throws {
    let _ = try await provider.request(
      .setNotificationPreference(category: category.rawValue, deviceUUID: deviceUUID, isEnabled: isEnabled)
    )
  }
}
