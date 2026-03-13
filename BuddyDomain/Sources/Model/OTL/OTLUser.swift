//
//  OTLUser.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

public struct OTLUser: Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let email: String
  public let studentNumber: Int
  public let degree: String
  public let majorDepartments: [Department]
  public let interestedDepartments: [Department]

  public init(
    id: Int,
    name: String,
    email: String,
    studentNumber: Int,
    degree: String,
    majorDepartments: [Department],
    interestedDepartments: [Department]
  ) {
    self.id = id
    self.name = name
    self.email = email
    self.studentNumber = studentNumber
    self.degree = degree
    self.majorDepartments = majorDepartments
    self.interestedDepartments = interestedDepartments
  }
}
