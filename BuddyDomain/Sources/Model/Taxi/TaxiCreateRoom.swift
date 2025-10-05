//
//  TaxiCreateRoom.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation

public struct TaxiCreateRoom {
  public var title: String
  public var source: TaxiLocation
  public var destination: TaxiLocation
  public var departureTime: Date
  public var capacity: Int

  public init(
    title: String,
    source: TaxiLocation,
    destination: TaxiLocation,
    departureTime: Date,
    capacity: Int
  ) {
    self.title = title
    self.source = source
    self.destination = destination
    self.departureTime = departureTime
    self.capacity = capacity
  }
}
