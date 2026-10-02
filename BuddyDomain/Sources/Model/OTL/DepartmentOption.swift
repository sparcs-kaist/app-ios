//
//  DepartmentOption.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation

/// A department that lectures can be filtered by.
public struct DepartmentOption: Identifiable, Hashable, Sendable {
  public let id: Int
  public let name: String
  public let code: String

  public init(id: Int, name: String, code: String) {
    self.id = id
    self.name = name
    self.code = code
  }
}
