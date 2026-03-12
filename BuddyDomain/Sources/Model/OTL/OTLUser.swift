//
//  OTLUser.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

public struct OTLUser: Identifiable, Sendable {
  public let id: Int
  public let email: String
  public let studentID: String
  public let firstName: String
  public let lastName: String

  public init(
    id: Int,
    email: String,
    studentID: String,
    firstName: String,
    lastName: String
  ) {
    self.id = id
    self.email = email
    self.studentID = studentID
    self.firstName = firstName
    self.lastName = lastName
  }
}
