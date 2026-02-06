//
//  FCMUseCase.swift
//  BuddyDataiOS
//
//  Created by 하정우 on 2/4/26.
//

import Foundation
import BuddyDomain
import KeychainSwift
import UIKit

public final class FCMUseCase: FCMUseCaseProtocol, @unchecked Sendable {
  private let keychain = KeychainSwift()
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
      language: Bundle.main.preferredLocalizations.first ?? "ko" // fallback to Korean
    )
  }
  
  public func manage(service: FeatureType, isActive: Bool) async throws {
    try await fcmRepository.manage(service: service, isActive: isActive)
  }
}
