//
//  Department.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct Department: Identifiable, Hashable, Sendable, Codable {
  public let id: Int
  public let name: String
  public let code: String?

  public init(id: Int, name: String, code: String?) {
    self.id = id
    self.name = name
    self.code = code
  }
}
