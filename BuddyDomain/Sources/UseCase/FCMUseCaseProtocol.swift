//
//  FCMUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/4/26.
//

public protocol FCMUseCaseProtocol: Sendable {
  func register(fcmToken: String) async throws
  func manage(service: FeatureType, isActive: Bool) async throws
}
