//
//  FCMUseCase.swift
//  BuddyDataiOS
//
//  Created by 하정우 on 2/4/26.
//

import Foundation
import BuddyDomain
import BuddyDataCore
import UIKit

public final class FCMUseCase: FCMUseCaseProtocol, @unchecked Sendable {
  private let keychain = Keychain()
  private static let fcmDeviceIDKey: String = "fcmDeviceID"
  
  private let fcmRepository: FCMRepositoryProtocol
  
  public init(fcmRepository: FCMRepositoryProtocol) {
    self.fcmRepository = fcmRepository
    
    keychain.accessGroup = "N5V8W52U3U.org.sparcs.soap"
  }
  
  public func register(fcmToken: String) async throws {
    let deviceUUID = keychain.get(FCMUseCase.fcmDeviceIDKey) ?? {
      let deviceUUID = UUID().uuidString
      keychain.set(deviceUUID, forKey: FCMUseCase.fcmDeviceIDKey)
      
      return deviceUUID
    }()
    
    try await fcmRepository.register(
      deviceUUID: deviceUUID,
      fcmToken: fcmToken,
      deviceName: UIDevice.current.name,
      language: Self.appLanguage
    )
  }
  
  /// The app's language as the backend expects it: a bare language code such as "en", since a
  /// localisation such as "en-GB" is rejected and the device is never registered.
  private static var appLanguage: String {
    guard let localization = Bundle.main.preferredLocalizations.first else {
      return "ko" // fallback to Korean
    }
    return Locale(identifier: localization).language.languageCode?.identifier ?? "ko"
  }

  public func manage(service: FeatureType, isActive: Bool) async throws {
    try await fcmRepository.manage(service: service, isActive: isActive)
  }
}
