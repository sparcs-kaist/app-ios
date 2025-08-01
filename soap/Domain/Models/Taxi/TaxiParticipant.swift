//
//  TaxiParticipant.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

struct TaxiParticipant: Identifiable, Hashable {
  enum SettlementType: String {
    case notDeparted = "not-departed"
    case requestedSettlement = "paid"
    case paymentRequired = "send-required"
    case paymentSent = "sent"
  }

  let id: String
  let name: String
  let nickname: String
  let profileImageURL: URL?
  let withdraw: Bool
  let isSettlement: SettlementType?
  let readAt: Date
}
