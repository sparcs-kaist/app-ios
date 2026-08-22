//
//  FCMUseCase.swift
//  BuddyDataiOS
//
//  Created by 하정우 on 2/4/26.
//

import Foundation
import BuddyDomain
import BuddyDataCore
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public final class FCMUseCase: FCMUseCaseProtocol, @unchecked Sendable {
  private let keychain = Keychain()
  private static let fcmDeviceIDKey: String = "fcmDeviceID"

  /// Label shown in the server's registered-device list. AppKit has no `UIDevice`,
  /// so macOS falls back to the machine's sharing name.
  private static var currentDeviceName: String {
    #if os(iOS)
    UIDevice.current.name
    #elseif os(macOS)
    Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    #endif
  }
  
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
      deviceName: Self.currentDeviceName,
      language: Bundle.main.preferredLocalizations.first ?? "ko" // fallback to Korean
    )
  }
  
  public func manage(service: FeatureType, isActive: Bool) async throws {
    try await fcmRepository.manage(service: service, isActive: isActive)
  }
}
