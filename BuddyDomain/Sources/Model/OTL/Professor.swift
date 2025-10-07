//
//  Professor.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct Professor: Identifiable, Sendable, Codable {
  public let id: Int
  public let name: LocalizedString
  public let reviewTotalWeight: Double

  public init(id: Int, name: LocalizedString, reviewTotalWeight: Double) {
    self.id = id
    self.name = name
    self.reviewTotalWeight = reviewTotalWeight
  }
}
