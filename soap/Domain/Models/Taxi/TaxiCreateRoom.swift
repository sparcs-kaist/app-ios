//
//  TaxiCreateRoom.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation

struct TaxiCreateRoom {
  var title: String
  var source: TaxiLocation
  var destination: TaxiLocation
  var departureTime: Date
  var capacity: Int
}
