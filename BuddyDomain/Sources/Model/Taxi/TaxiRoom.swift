//
//  TaxiRoom.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

public struct TaxiRoom: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let source: TaxiLocation
  public let destination: TaxiLocation
  public let departAt: Date
  public let participants: [TaxiParticipant]
  public let madeAt: Date
  public let capacity: Int
  public let settlementTotal: Int?
  public let isDeparted: Bool
  public let isOver: Bool?

  public init(
    id: String,
    title: String,
    source: TaxiLocation,
    destination: TaxiLocation,
    departAt: Date,
    participants: [TaxiParticipant],
    madeAt: Date,
    capacity: Int,
    settlementTotal: Int?,
    isDeparted: Bool,
    isOver: Bool?
  ) {
    self.id = id
    self.title = title
    self.source = source
    self.destination = destination
    self.departAt = departAt
    self.participants = participants
    self.madeAt = madeAt
    self.capacity = capacity
    self.settlementTotal = settlementTotal
    self.isDeparted = isDeparted
    self.isOver = isOver
  }
}
