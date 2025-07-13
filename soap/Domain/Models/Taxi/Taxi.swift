//
//  TaxiLocation.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//
import Foundation

struct TaxiLocationOld: Identifiable, Hashable {
  let id: String
  let title: String
  let priority: Double
  let latitude: Double
  let longitude: Double
}

struct RoomInfo {
  var source: TaxiLocationOld
  var destination: TaxiLocationOld
  var name: String
  var occupancy: Int
  var capacity: Int
  var departureTime: Date
}
