//
//  TaxiRoom.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

public struct TaxiRoom: Identifiable, Hashable {
  public let id: String
  let title: String
  let from: TaxiLocationShort
  let to: TaxiLocationShort
  let departAt: Date
  let participants: [TaxiParticipant]
  let madeAt: Date
  let capacity: Int
  let isDeparted: Bool
}
