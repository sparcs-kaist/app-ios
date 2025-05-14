//
//  TaxiLocation.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//
import Foundation

struct TaxiLocation: Identifiable, Hashable {
  let id: String
  let title: String
  let priority: Double
  let latitude: Double
  let longitude: Double
}

struct RoomInfo {
  var origin: TaxiLocation
  var destination: TaxiLocation
  var name: String
  var occupancy: Int
  var capacity: Int
  var departureTime: Date
}
