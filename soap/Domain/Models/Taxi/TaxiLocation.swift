//
//  TaxiLocation.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

struct TaxiLocation: Identifiable, Hashable {
  let id: String
  let title: LocalizedString
  let priority: Double
  let latitude: Double
  let longitude: Double
}
