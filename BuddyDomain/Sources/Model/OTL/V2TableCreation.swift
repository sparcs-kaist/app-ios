//
//  TableCreation.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 02/03/2026.
//

import Foundation

public struct TableCreation: Identifiable, Codable, Sendable {
  public let id: Int

  public init(id: Int) {
    self.id = id
  }
}
