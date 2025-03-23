//
//  TaxiLocation.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//

struct TaxiLocation: Identifiable, Hashable {
  let id: String
  let title: String
  let priority: Double
  let latitude: Double
  let longitude: Double
}
