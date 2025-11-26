//
//  TaxiParticipant.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

public struct TaxiParticipant: Identifiable, Hashable, Sendable {
  public enum SettlementType: String, Sendable {
    case notDeparted = "not-departed"
    case requestedSettlement = "paid"
    case paymentRequired = "send-required"
    case paymentSent = "sent"
  }

  public let id: String
  public let name: String
  public let nickname: String
  public let profileImageURL: URL?
  public let withdraw: Bool
  public let badge: Bool
  public let isSettlement: SettlementType?
  public let readAt: Date

  public init(
    id: String,
    name: String,
    nickname: String,
    profileImageURL: URL?,
    withdraw: Bool,
    badge: Bool,
    isSettlement: SettlementType?,
    readAt: Date
  ) {
    self.id = id
    self.name = name
    self.nickname = nickname
    self.profileImageURL = profileImageURL
    self.withdraw = withdraw
    self.badge = badge
    self.isSettlement = isSettlement
    self.readAt = readAt
  }
}
