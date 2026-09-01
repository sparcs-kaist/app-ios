//
//  FCMRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/4/26.
//

import Foundation

public protocol FCMRepositoryProtocol: Sendable {
  func register(deviceUUID: String, fcmToken: String, deviceName: String, language: String) async throws
  func manage(service: FeatureType, isActive: Bool) async throws
}
