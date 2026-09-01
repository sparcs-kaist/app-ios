//
//  TaxiRoomUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 10/29/25.
//

import Foundation

public protocol TaxiRoomUseCaseProtocol: Sendable {
  func isBlocked() async -> TaxiRoomBlockStatus
}
