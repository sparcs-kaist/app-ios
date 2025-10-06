//
//  SessionBridgeServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation

public protocol SessionBridgeServiceProtocol {
  func start()
  func updateAppContext(_ context: [String: Any])
}
