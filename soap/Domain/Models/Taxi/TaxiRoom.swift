//
//  TaxiRoom.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

public struct TaxiRoom: Identifiable, Hashable, Sendable {
  public let id: String
  let title: String
  let source: TaxiLocation
  let destination: TaxiLocation
  let departAt: Date
  let participants: [TaxiParticipant]
  let madeAt: Date
  let capacity: Int
  let settlementTotal: Int?
  let isDeparted: Bool
  let isOver: Bool?
}
