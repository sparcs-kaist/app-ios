//
//  Department.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation

public struct Department: Identifiable, Hashable, Sendable {
  public let id: Int
  public let name: LocalizedString
  public let code: String

  public init(id: Int, name: LocalizedString, code: String) {
    self.id = id
    self.name = name
    self.code = code
  }
}
